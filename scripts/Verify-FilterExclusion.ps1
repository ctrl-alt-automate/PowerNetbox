#Requires -Version 7

<#
.SYNOPSIS
    Verify that every Get-NB* function declaring -Brief, -Fields, and -Omit
    parameters invokes AssertNBMutualExclusiveParam in its process block.

.DESCRIPTION
    Drift-detection auditor introduced as PR #397 PR-2. The original PR
    added the AssertNBMutualExclusiveParam helper and applied it to three
    pilot functions; this script enforces that the invariant holds across
    every Get function in the codebase.

    Uses the PowerShell AST to locate:
    - FunctionDefinitionAst nodes whose param block declares all three
      Brief/Fields/Omit parameters
    - CommandAst nodes inside process {} that invoke
      AssertNBMutualExclusiveParam with a -Parameters argument containing
      all three names

    Reports a finding for every Get function that declares all three
    filter parameters but does not invoke the assertion correctly.

    Future Get functions cannot silently regress the invariant because
    this script is gated in CI via .github/workflows/test.yml.

.PARAMETER Path
    Root directory to scan. Defaults to ./Functions relative to the
    script's parent.

.PARAMETER OutputFormat
    'Table' (default, human-readable) or 'Json' (machine-readable for CI).

.PARAMETER FailOnMismatch
    Exit with non-zero code if any findings are reported. Intended for CI.

.PARAMETER SkipExemptions
    Bypass the scripts/filter-exclusion-exemptions.txt list. Useful for
    discovering whether a previously-exempted file should still be exempt.

.EXAMPLE
    ./scripts/Verify-FilterExclusion.ps1

    Scan all Get-NB* functions and print a human-readable table.

.EXAMPLE
    ./scripts/Verify-FilterExclusion.ps1 -FailOnMismatch -OutputFormat Json

    CI-ready invocation: exits non-zero on findings, emits JSON.

.NOTES
    Related: PR #391 (Verify-ValidateSetParity.ps1) — same AST-based
    auditor pattern applied to a different invariant.
#>

[CmdletBinding()]
param(
    [string]$Path,

    [ValidateSet('Table', 'Json')]
    [string]$OutputFormat = 'Table',

    [switch]$FailOnMismatch,

    [switch]$SkipExemptions
)

$ErrorActionPreference = 'Stop'

# Resolve the Functions/ directory relative to the script if not supplied
if (-not $Path) {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $Path = Join-Path (Split-Path -Parent $scriptDir) 'Functions'
}

if (-not (Test-Path $Path)) {
    Write-Error "Functions directory not found: $Path"
    exit 2
}

# Load exemptions (file paths relative to the repo root, one per line, # for comments)
$exemptions = @()
if (-not $SkipExemptions) {
    $exemptionsFile = Join-Path (Split-Path -Parent $PSCommandPath) 'filter-exclusion-exemptions.txt'
    if (Test-Path $exemptionsFile) {
        $exemptions = Get-Content $exemptionsFile |
            Where-Object { $_ -and -not $_.StartsWith('#') } |
            ForEach-Object { $_.Trim() }
    }
}

# The three required parameter names
$requiredParams = @('Brief', 'Fields', 'Omit')

function Get-FilterExclusionFinding {
    <#
    .SYNOPSIS
        Inspect one .ps1 file and return zero or more findings.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $FilePath,
        [ref]$tokens,
        [ref]$errors
    )

    if ($errors.Count -gt 0) {
        Write-Warning "Parse errors in $FilePath — skipping: $($errors[0].Message)"
        return
    }

    $functions = $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true
    )

    foreach ($fn in $functions) {
        # Only inspect Get-NB* functions
        if ($fn.Name -notmatch '^Get-NB') { continue }

        # Collect declared parameter names
        $paramBlock = $fn.Body.ParamBlock
        if ($null -eq $paramBlock) { continue }
        $declaredParams = $paramBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }

        # Must declare all three to be in scope
        $missingFromDeclared = $requiredParams | Where-Object { $_ -notin $declaredParams }
        if ($missingFromDeclared.Count -gt 0) { continue }

        # Find all CommandAst nodes in the entire function body (any block, any depth)
        $commands = $fn.Body.FindAll(
            { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
            $true
        )

        $assertionFound = $false
        foreach ($cmd in $commands) {
            $cmdName = $cmd.GetCommandName()
            if ($cmdName -ne 'AssertNBMutualExclusiveParam') { continue }

            # Extract the -Parameters argument's values
            $paramsArgValues = @()
            for ($i = 0; $i -lt $cmd.CommandElements.Count; $i++) {
                $elem = $cmd.CommandElements[$i]
                if ($elem -is [System.Management.Automation.Language.CommandParameterAst] -and
                    $elem.ParameterName -eq 'Parameters') {
                    # Value is the next element (or multiple, if comma-separated array)
                    $j = $i + 1
                    while ($j -lt $cmd.CommandElements.Count) {
                        $valueElem = $cmd.CommandElements[$j]
                        if ($valueElem -is [System.Management.Automation.Language.CommandParameterAst]) { break }

                        # Typical form: an ArrayLiteralAst with StringConstantAst children,
                        # or a sequence of StringConstantAst separated by commas (PowerShell
                        # parser produces either depending on style).
                        if ($valueElem -is [System.Management.Automation.Language.ArrayLiteralAst]) {
                            $paramsArgValues += $valueElem.Elements | ForEach-Object {
                                if ($_ -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                                    $_.Value
                                }
                            }
                        } elseif ($valueElem -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                            $paramsArgValues += $valueElem.Value
                        }
                        $j++
                    }
                    break
                }
            }

            # Check that all three required parameter names are present
            $missingFromArg = $requiredParams | Where-Object { $_ -notin $paramsArgValues }
            if ($missingFromArg.Count -eq 0) {
                $assertionFound = $true
                break
            }
        }

        if (-not $assertionFound) {
            [PSCustomObject]@{
                File          = $FilePath
                Function      = $fn.Name
                DeclaredParams = ($requiredParams -join ', ')
                Status        = 'Missing AssertNBMutualExclusiveParam'
            }
        }
    }
}

# Collect findings across all Get-NB* files
$allFindings = @()
$targetFiles = Get-ChildItem -Path $Path -Recurse -Filter 'Get-NB*.ps1' -File
foreach ($file in $targetFiles) {
    # Normalise path for exemption match (relative to repo root with forward slashes)
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $file.FullName).Replace('\', '/')
    if ($relativePath -in $exemptions) {
        continue
    }

    $findings = Get-FilterExclusionFinding -FilePath $file.FullName
    if ($findings) { $allFindings += $findings }
}

# Emit output
switch ($OutputFormat) {
    'Json' {
        $allFindings | ConvertTo-Json -Depth 5
    }
    default {
        if ($allFindings.Count -eq 0) {
            Write-Host "No missing AssertNBMutualExclusiveParam invocations found." -ForegroundColor Green
        } else {
            $allFindings | Format-Table -AutoSize @{
                Name = 'File'
                Expression = {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
                    [System.IO.Path]::GetRelativePath($repoRoot, $_.File).Replace('\', '/')
                }
            }, Function, Status
            Write-Host ""
            Write-Host "Summary: $($allFindings.Count) function(s) missing AssertNBMutualExclusiveParam invocation." -ForegroundColor Yellow
        }
    }
}

# Exit handling for CI
if ($FailOnMismatch -and $allFindings.Count -gt 0) {
    exit 1
}
