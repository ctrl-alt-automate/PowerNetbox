#Requires -Version 7

<#
.SYNOPSIS
    Verify that PowerNetbox ValidateSet values match NetBox's ChoiceSet values.

.DESCRIPTION
    For every [ValidateSet(...)] decorator on a string parameter in the
    PowerNetbox Functions/ tree, find the best-matching ChoiceSet class in
    NetBox's choices.py source files and report any discrepancies (missing
    values, extra/unknown values). This catches the class of bug where a
    PowerShell ValidateSet silently drifts from the real API enum — see
    issues #360 (Interface Mode), #385 (Get-NBBranch -Status), #389
    (Cable_Profile).

    The script uses the PowerShell AST to extract ValidateSets reliably
    (handles multi-line declarations, embedded comments, and [Alias] lines),
    and a line-based parser to extract ChoiceSet values from NetBox's
    choices.py files (their structure is consistent and simple).

    Matching is done by value overlap: for each PowerNetbox ValidateSet we
    pick the NetBox ChoiceSet with the highest fraction of PowerNetbox values
    also present in NetBox. Sets below MinOverlapThreshold are treated as
    PowerNetbox-internal validation (e.g. length units, output formats) and
    skipped.

.PARAMETER NetboxVersion
    NetBox git tag to check against (e.g. 'v4.5.7'). Defaults to the latest
    stable release fetched from the GitHub API.

.PARAMETER FunctionsPath
    Path to the PowerNetbox Functions directory. Defaults to ./Functions
    (relative to the repo root).

.PARAMETER OutputFormat
    Output format: 'Console' (human-readable, default) or 'Json'.

.PARAMETER MinOverlapThreshold
    Minimum fraction of PowerNetbox values that must be present in a NetBox
    ChoiceSet for the match to be considered. Default: 0.3 (30%). Lower this
    to surface more candidate matches; raise it to reduce false positives.

.PARAMETER FailOnMismatch
    Exit with code 1 if any discrepancies are found. Useful in CI.

.PARAMETER ExclusionFile
    Path to a file listing known-OK discrepancies to suppress. Format: one
    entry per line as 'RelativeFile::ParameterName', with '#' line comments
    allowed. Defaults to ./scripts/validateset-parity-exclusions.txt if it
    exists. Use this to gate CI against actual regressions without being
    drowned in known false positives.

.EXAMPLE
    ./scripts/Verify-ValidateSetParity.ps1

    Check every ValidateSet against the latest stable NetBox release,
    print a human-readable report to the console.

.EXAMPLE
    ./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.7

    Check against a pinned NetBox version.

.EXAMPLE
    ./scripts/Verify-ValidateSetParity.ps1 -OutputFormat Json |
        ConvertFrom-Json | Where-Object Parameter -eq 'Cable_Profile'

    Machine-readable output for scripting / CI.

.EXAMPLE
    ./scripts/Verify-ValidateSetParity.ps1 -FailOnMismatch

    Exit non-zero on any discrepancy — suitable for a CI gate on NetBox
    compat bumps.

.NOTES
    Known limitations:
    - Only extracts string-literal values from ChoiceSet classes. If NetBox
      defines a value by referencing another constant (e.g.
      `VALUE = OtherClass.SOMEVALUE`) it is skipped.
    - Matching is heuristic (Jaccard-like overlap). A ValidateSet that
      coincidentally overlaps with an unrelated ChoiceSet may produce a
      confusing report — the overlap percentage in the output makes this
      diagnosable.
    - Only looks at string-type parameters. ValidateSets on int/enum-like
      numeric parameters are skipped.
#>
[CmdletBinding()]
param(
    [string]$NetboxVersion,

    [string]$FunctionsPath = './Functions',

    [ValidateSet('Console', 'Json')]
    [string]$OutputFormat = 'Console',

    [ValidateRange(0.0, 1.0)]
    [double]$MinOverlapThreshold = 0.3,

    [switch]$FailOnMismatch,

    [string]$ExclusionFile
)

$ErrorActionPreference = 'Stop'

# --------------------------------------------------------------------------
# 1. Resolve NetBox version
# --------------------------------------------------------------------------

if (-not $NetboxVersion) {
    Write-Host "Resolving latest NetBox release..." -ForegroundColor DarkGray
    $release = Invoke-RestMethod 'https://api.github.com/repos/netbox-community/netbox/releases/latest'
    $NetboxVersion = $release.tag_name
    Write-Host "Latest: $NetboxVersion" -ForegroundColor DarkGray
}

# --------------------------------------------------------------------------
# 2. Fetch and parse NetBox choices.py files
# --------------------------------------------------------------------------

# NetBox scatters ChoiceSet definitions across one choices.py per app.
$choicesApps = @(
    'dcim', 'ipam', 'circuits', 'virtualization', 'tenancy',
    'vpn', 'wireless', 'extras', 'core', 'users'
)

# Map of ChoiceSet class name -> list of string values.
# Keyed on class name so matching can prefer semantically-meaningful names.
$netboxChoices = [ordered]@{}

foreach ($app in $choicesApps) {
    $url = "https://raw.githubusercontent.com/netbox-community/netbox/$NetboxVersion/netbox/$app/choices.py"
    try {
        $content = Invoke-RestMethod -Uri $url -ErrorAction Stop
    }
    catch {
        Write-Verbose "Skipping $app/choices.py (HTTP fetch failed, app may not define choices)"
        continue
    }

    # Line-based parser. We track whether we're inside a `class XxxChoices(...)`
    # block and collect `CONSTANT = 'value'` lines that appear at class-body
    # indentation (4 spaces). We stop collecting when a new top-level class or
    # function begins.
    $currentClass = $null
    $currentValues = [System.Collections.Generic.List[string]]::new()

    foreach ($line in ($content -split "`n")) {
        # Enter a ChoiceSet class. We accept any base class whose name ends
        # in 'Choices' or 'ChoiceSet' — NetBox has subclasses like
        # `class CableLengthUnitChoices(ChoiceSet)` and variants.
        if ($line -match '^class\s+(\w+)\s*\(\s*(?:\w+\.)?(?:ChoiceSet|Choices)\b') {
            # Flush previous
            if ($currentClass -and $currentValues.Count -gt 0) {
                $netboxChoices["$app.$currentClass"] = $currentValues.ToArray()
            }
            $currentClass = $matches[1]
            $currentValues = [System.Collections.Generic.List[string]]::new()
            continue
        }

        # Leave on any new top-level def/class (dedent to column 0).
        if ($currentClass -and $line -match '^(class|def)\s') {
            if ($currentValues.Count -gt 0) {
                $netboxChoices["$app.$currentClass"] = $currentValues.ToArray()
            }
            $currentClass = $null
            $currentValues = [System.Collections.Generic.List[string]]::new()
            continue
        }

        if ($currentClass) {
            # Simple string literal assignment at class-body indent:
            #     CONSTANT_NAME = 'value'                    [optional  # comment]
            # We accept 4-space or 8-space indent. Values with spaces or
            # special chars are fine; we only require a single quoted literal.
            # IMPORTANT: -cmatch (case-sensitive) so we don't catch lowercase
            # metadata lines like `key = 'Device.status'` in the class body.
            # Trailing inline comments are common in NetBox source (e.g.
            # `TYPE_1GE_FIXED = '1000base-t'  # TODO: Rename to _T`) and must
            # not break the match.
            if ($line -cmatch '^\s{4,8}([A-Z][A-Z0-9_]*)\s*=\s*[''"]([^''"]+)[''"]\s*(#.*)?$') {
                $null = $currentValues.Add($matches[2])
            }
        }
    }
    # Flush last class in file
    if ($currentClass -and $currentValues.Count -gt 0) {
        $netboxChoices["$app.$currentClass"] = $currentValues.ToArray()
    }
}

Write-Host "Extracted $($netboxChoices.Count) ChoiceSet classes from NetBox $NetboxVersion" -ForegroundColor DarkGray

if ($netboxChoices.Count -eq 0) {
    Write-Error "No ChoiceSet classes extracted. Check network access to raw.githubusercontent.com and the NetBox version tag."
    exit 2
}

# --------------------------------------------------------------------------
# 3. Extract ValidateSets from PowerNetbox via AST
# --------------------------------------------------------------------------

if (-not (Test-Path $FunctionsPath)) {
    Write-Error "Functions path not found: $FunctionsPath"
    exit 2
}

$functionsRoot = (Resolve-Path $FunctionsPath).Path
$powerNetboxSets = [System.Collections.Generic.List[pscustomobject]]::new()

$files = Get-ChildItem $FunctionsPath -Recurse -Filter '*.ps1'
foreach ($file in $files) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$tokens, [ref]$parseErrors)

    if ($parseErrors.Count -gt 0) {
        Write-Warning "Parse errors in $($file.Name), skipping: $($parseErrors[0].Message)"
        continue
    }

    # Find every ValidateSet attribute in the file
    $validateSetAttrs = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.AttributeAst] -and
            $node.TypeName.Name -eq 'ValidateSet'
        }, $true)

    foreach ($attr in $validateSetAttrs) {
        # Walk up to the parameter declaration
        $paramAst = $attr.Parent
        while ($paramAst -and $paramAst -isnot [System.Management.Automation.Language.ParameterAst]) {
            $paramAst = $paramAst.Parent
        }
        if (-not $paramAst) { continue }

        # Only consider string parameters — ValidateSets on numeric types are
        # usually internal enums, not NetBox API values.
        $typeName = $null
        foreach ($a in $paramAst.Attributes) {
            if ($a -is [System.Management.Automation.Language.TypeConstraintAst]) {
                $typeName = $a.TypeName.Name
                break
            }
        }
        if ($typeName -and $typeName -notmatch '^(string|String)(\[\])?$') {
            continue
        }

        # Extract the string literal arguments. Skip named arguments like
        # `IgnoreCase = $true` which appear as AssignmentStatementAst, not
        # in PositionalArguments.
        $values = @(
            $attr.PositionalArguments |
                Where-Object { $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] } |
                ForEach-Object { $_.Value }
        )
        if ($values.Count -eq 0) { continue }

        # Walk up to the enclosing function for reporting
        $funcAst = $paramAst
        while ($funcAst -and $funcAst -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) {
            $funcAst = $funcAst.Parent
        }

        $relPath = $file.FullName.Substring($functionsRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/', '\')
        $powerNetboxSets.Add([pscustomobject]@{
                File      = $relPath
                Function  = if ($funcAst) { $funcAst.Name } else { '<script>' }
                Parameter = $paramAst.Name.VariablePath.UserPath
                Values    = $values
                Count     = $values.Count
            })
    }
}

Write-Host "Extracted $($powerNetboxSets.Count) string-type ValidateSets from PowerNetbox" -ForegroundColor DarkGray

# --------------------------------------------------------------------------
# 4. Match and diff
# --------------------------------------------------------------------------
#
# Matching is a combined score across multiple signals because neither
# pure name-matching nor pure value-overlap is reliable alone:
#
#   - Value overlap alone misses bugs where every PowerNetbox value is
#     subtly malformed (e.g. #389 Cable_Profile: '1c1p' vs 'single-1c1p'
#     → zero intersection, would be skipped).
#   - Name matching alone over-matches generic names like '-Status', which
#     exist on dozens of NetBox ChoiceSets.
#
# Score components (weighted sum, higher is better):
#
#   name_score        : parameter name vs. ChoiceSet class name after
#                       normalisation (lowercase, strip _ and 'Choices').
#                       1.0 exact, 0.6 substring, 0.0 none.
#   value_exact       : fraction of PN values exactly in NB.
#   value_suffix      : fraction of PN values that are suffix of some NB
#                       value (e.g. '1c1p' is suffix of 'single-1c1p').
#                       This is what catches prefix-stripping bugs.
#   app_bonus         : +0.15 if the function file lives in a dir whose
#                       name matches the NetBox app the ChoiceSet came
#                       from (e.g. Functions/DCIM/... matches dcim.*).
#
# A match is kept when:
#   total_score >= MinOverlapThreshold AND (value_exact < 1.0 or
#   there are missing values from the NB side).
#
# The report's "Overlap" column displays the total score as a percentage
# so users can judge match confidence.

function Get-NormalizedName {
    param([string]$Name)
    # Lowercase, strip underscores and trailing "Choices" / "ChoiceSet".
    $n = $Name.ToLowerInvariant() -replace '[_\s]', ''
    $n = $n -replace 'choices$', '' -replace 'choiceset$', ''
    return $n
}

function Get-FunctionApp {
    param([string]$RelativeFilePath)
    # Functions/DCIM/.../Xxx.ps1 -> 'dcim'
    # Functions/Plugins/Branching/... -> '' (no app hint)
    $parts = $RelativeFilePath -split '[\\/]'
    if ($parts.Count -ge 1) {
        $top = $parts[0].ToLowerInvariant()
        switch ($top) {
            'dcim'           { return 'dcim' }
            'ipam'           { return 'ipam' }
            'virtualization' { return 'virtualization' }
            'circuits'       { return 'circuits' }
            'tenancy'        { return 'tenancy' }
            'vpn'            { return 'vpn' }
            'wireless'       { return 'wireless' }
            'extras'         { return 'extras' }
            'core'           { return 'core' }
            'users'          { return 'users' }
            default          { return '' }
        }
    }
    return ''
}

# Load exclusion list (default to scripts/validateset-parity-exclusions.txt if
# present). Each line is 'Relative/Path.ps1::ParameterName'. '#' line comments
# and blank lines are ignored.
$exclusions = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
if (-not $ExclusionFile) {
    $defaultExclusion = Join-Path $PSScriptRoot 'validateset-parity-exclusions.txt'
    if (Test-Path $defaultExclusion) {
        $ExclusionFile = $defaultExclusion
    }
}
if ($ExclusionFile -and (Test-Path $ExclusionFile)) {
    foreach ($line in (Get-Content $ExclusionFile)) {
        $trimmed = $line.Trim()
        if ($trimmed -and -not $trimmed.StartsWith('#')) {
            # Normalise path separators so Windows/Unix entries both match.
            $normalised = $trimmed -replace '\\', '/'
            $null = $exclusions.Add($normalised)
        }
    }
    Write-Host "Loaded $($exclusions.Count) exclusions from $ExclusionFile" -ForegroundColor DarkGray
}

$findings = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($pn in $powerNetboxSets) {
    # Skip if this File::Parameter is in the exclusion list.
    $key = "$($pn.File -replace '\\', '/')::$($pn.Parameter)"
    if ($exclusions.Contains($key)) {
        continue
    }


    $pnSet = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]$pn.Values, [StringComparer]::OrdinalIgnoreCase)

    $pnAppHint = Get-FunctionApp -RelativeFilePath $pn.File
    $pnParamNormalized = Get-NormalizedName -Name $pn.Parameter

    $bestMatch = $null
    $bestScore = 0.0

    foreach ($entry in $netboxChoices.GetEnumerator()) {
        $nbApp = ($entry.Key -split '\.')[0]
        $nbClass = ($entry.Key -split '\.')[1]
        $nbValues = $entry.Value
        $nbSet = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$nbValues, [StringComparer]::OrdinalIgnoreCase)

        # --- 1. name_score ---
        $nbClassNormalized = Get-NormalizedName -Name $nbClass
        $nameScore = 0.0
        if ($pnParamNormalized -eq $nbClassNormalized) {
            $nameScore = 1.0
        }
        elseif ($nbClassNormalized -and (
                $nbClassNormalized.Contains($pnParamNormalized) -or
                $pnParamNormalized.Contains($nbClassNormalized))) {
            $nameScore = 0.6
        }

        # --- 2. value_exact ---
        $intersection = [System.Collections.Generic.HashSet[string]]::new(
            $pnSet, [StringComparer]::OrdinalIgnoreCase)
        $intersection.IntersectWith($nbSet)
        $valueExact = if ($pnSet.Count -gt 0) {
            $intersection.Count / $pnSet.Count
        } else { 0 }

        # --- 3. value_suffix ---
        # How many PN values appear as a suffix of some NB value?
        # This catches prefix-stripped mistakes.
        $suffixMatches = 0
        foreach ($pnVal in $pn.Values) {
            foreach ($nbVal in $nbValues) {
                if ($nbVal.EndsWith("-$pnVal", [StringComparison]::OrdinalIgnoreCase) -or
                    $nbVal -eq $pnVal) {
                    $suffixMatches++
                    break
                }
            }
        }
        $valueSuffix = if ($pnSet.Count -gt 0) {
            $suffixMatches / $pnSet.Count
        } else { 0 }

        # --- 4. app_bonus ---
        $appBonus = if ($pnAppHint -and $pnAppHint -eq $nbApp) { 0.15 } else { 0.0 }

        # Weighted combination. Name is the strongest signal.
        $score = (0.45 * $nameScore) +
                 (0.30 * $valueExact) +
                 (0.10 * $valueSuffix) +
                 $appBonus

        $isBetter = $false
        if ($score -gt $bestScore) {
            $isBetter = $true
        }
        elseif ($score -eq $bestScore -and $bestMatch) {
            # Tie-break: when all PN values are already contained in this NB
            # ChoiceSet AND the previous best, prefer the NB set whose size is
            # closest to PN's size. This prevents a PN set matching exactly
            # against, say, VLANStatusChoices (3 values) but being attributed
            # to the superset PrefixStatusChoices (4 values) just because the
            # superset happened to iterate first with the same overall score.
            if ($valueExact -eq 1.0 -and $bestMatch.ValueExact -eq 1.0) {
                $newDistance = [math]::Abs($nbValues.Count - $pn.Count)
                $oldDistance = [math]::Abs($bestMatch.Entry.Value.Count - $pn.Count)
                if ($newDistance -lt $oldDistance) {
                    $isBetter = $true
                }
            }
        }

        if ($isBetter) {
            $bestScore = $score
            $bestMatch = [pscustomobject]@{
                Entry       = $entry
                NameScore   = $nameScore
                ValueExact  = $valueExact
                ValueSuffix = $valueSuffix
                AppBonus    = $appBonus
            }
        }
    }

    if (-not $bestMatch -or $bestScore -lt $MinOverlapThreshold) {
        continue  # Below threshold: assume PowerNetbox-internal validation
    }

    # Compute diff against the matched NB ChoiceSet.
    $nbValuesList = $bestMatch.Entry.Value
    $nbValues = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]$nbValuesList, [StringComparer]::OrdinalIgnoreCase)

    $missing = @($nbValuesList | Where-Object { -not $pnSet.Contains($_) }) | Sort-Object
    $extra = @($pn.Values | Where-Object { -not $nbValues.Contains($_) }) | Sort-Object

    if ($missing.Count -eq 0 -and $extra.Count -eq 0) {
        continue  # Perfect match on values
    }

    $findings.Add([pscustomobject]@{
            File        = $pn.File
            Function    = $pn.Function
            Parameter   = $pn.Parameter
            ChoiceSet   = $bestMatch.Entry.Key
            Score       = [math]::Round($bestScore * 100, 1)
            NameScore   = [math]::Round($bestMatch.NameScore * 100, 1)
            ValueExact  = [math]::Round($bestMatch.ValueExact * 100, 1)
            ValueSuffix = [math]::Round($bestMatch.ValueSuffix * 100, 1)
            Missing     = $missing
            Extra       = $extra
            PNCount     = $pn.Count
            NBCount     = $nbValuesList.Count
        })
}

# --------------------------------------------------------------------------
# 5. Output
# --------------------------------------------------------------------------

if ($OutputFormat -eq 'Json') {
    $findings | ConvertTo-Json -Depth 10
}
else {
    Write-Host ""
    if ($findings.Count -eq 0) {
        Write-Host "All ValidateSets match NetBox $NetboxVersion" -ForegroundColor Green
    }
    else {
        Write-Host "Found $($findings.Count) ValidateSet discrepancies vs NetBox $NetboxVersion" -ForegroundColor Yellow
        Write-Host ""

        foreach ($f in $findings | Sort-Object File, Parameter) {
            Write-Host "$($f.File)" -ForegroundColor Cyan
            Write-Host "  Function:  $($f.Function)"
            Write-Host "  Parameter: -$($f.Parameter)"
            Write-Host "  Match:     $($f.ChoiceSet) (score $($f.Score)%, name=$($f.NameScore)% exact=$($f.ValueExact)% suffix=$($f.ValueSuffix)%, PN=$($f.PNCount) NB=$($f.NBCount))"
            if ($f.Missing.Count -gt 0) {
                Write-Host "  Missing from PowerNetbox ($($f.Missing.Count)):" -ForegroundColor Red
                foreach ($v in $f.Missing) {
                    Write-Host "    + $v" -ForegroundColor Red
                }
            }
            if ($f.Extra.Count -gt 0) {
                Write-Host "  Extra in PowerNetbox ($($f.Extra.Count)):" -ForegroundColor Magenta
                foreach ($v in $f.Extra) {
                    Write-Host "    - $v" -ForegroundColor Magenta
                }
            }
            Write-Host ""
        }

        Write-Host "Summary: $($findings.Count) parameter(s) need attention." -ForegroundColor Yellow
    }
}

if ($FailOnMismatch -and $findings.Count -gt 0) {
    exit 1
}
