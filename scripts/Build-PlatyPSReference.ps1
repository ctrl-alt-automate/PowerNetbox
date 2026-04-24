<#
.SYNOPSIS
    Generates MkDocs-compatible Markdown reference pages for all public PowerNetbox cmdlets.

.DESCRIPTION
    Uses platyPS to produce one .md file per exported public cmdlet, then
    post-processes each file to inject MkDocs Material snippet-include markers
    for shared parameter docs (pagination, bulk ops, etc.).

    Files are written under -OutputPath, mirroring the Functions/ source tree:
        DCIM/Devices/Get-NBDCIMDevice.md
        IPAM/Addresses/Get-NBIPAMAddress.md
        ...

    The script auto-installs platyPS from PSGallery if it is not already
    available in the current user scope.

.PARAMETER ModulePath
    Path to the PowerNetbox.psd1 manifest (source). The script derives all
    sibling paths (Functions/, deploy.ps1, built manifest) from this path.

.PARAMETER OutputPath
    Root directory where generated .md files are written. Created if absent.
    Safe to re-run: existing files are overwritten (-Force).

.PARAMETER Scope
    'Public'   - export cmdlets matching '^[A-Z][a-z]+-NB' (default)
    'Internal' - export all other functions (helpers, setup)

.EXAMPLE
    # From the repo root:
    pwsh -NoProfile -File scripts/Build-PlatyPSReference.ps1 `
         -ModulePath PowerNetbox.psd1 `
         -OutputPath docs-build/generated/reference `
         -Scope Public
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ModulePath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [Parameter()]
    [ValidateSet('Public', 'Internal')]
    [string]$Scope = 'Public'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Ensure platyPS is available
# ---------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name platyPS)) {
    Write-Host 'platyPS not found - installing from PSGallery (user scope)...'
    Install-Module -Name platyPS -Scope CurrentUser -Force -ErrorAction Stop
}
Import-Module platyPS -ErrorAction Stop

# ---------------------------------------------------------------------------
# 2. Helper: inject snippet-include markers
# ---------------------------------------------------------------------------
function Invoke-SnippetInjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$CmdletName
    )

    $rawContent = Get-Content -Raw $FilePath
    $content = if ($null -eq $rawContent) { '' } else { $rawContent }

    # Skip injection if already done (idempotency guard)
    if ($content -match '(?m)^## Common parameters\s*$') {
        Write-Verbose "Skipping snippet injection for $CmdletName (already present)"
        return
    }

    # Determine which snippets this cmdlet needs
    $snippetsNeeded = @('common-request-params.md')
    if ($CmdletName -match '^Get-NB') {
        $snippetsNeeded += 'common-pagination-params.md'
    }

    $bulkSupported = @(
        'New-NBDCIMDevice', 'New-NBDCIMInterface',
        'New-NBIPAMAddress', 'New-NBIPAMPrefix', 'New-NBIPAMVLAN',
        'New-NBVirtualMachine', 'New-NBVirtualMachineInterface',
        'Set-NBDCIMDevice', 'Remove-NBDCIMDevice'
    )
    if ($bulkSupported -contains $CmdletName) {
        $snippetsNeeded += 'common-bulk-params.md'
    }

    # Build the injection block
    $injection = "`n## Common parameters`n`n"
    foreach ($snippet in $snippetsNeeded) {
        $title = ($snippet -replace '\.md$', '') -replace '-', ' '
        $injection += "<details markdown>`n<summary>$title</summary>`n`n--8<-- `"$snippet`"`n`n</details>`n`n"
    }

    # Insert before ## RELATED LINKS (platyPS emits all-caps), or append at end
    $relatedLinksPattern = '(?m)^## (RELATED LINKS|Related Links)\s*$'
    if ($content -match $relatedLinksPattern) {
        $content = $content -replace $relatedLinksPattern, "${injection}## `$1"
    } else {
        $content += $injection
    }

    Set-Content -Path $FilePath -Value $content -NoNewline
}

# ---------------------------------------------------------------------------
# 3. Resolve paths and build source-file -> subpath hashmap
# ---------------------------------------------------------------------------
$ModulePath = [System.IO.Path]::GetFullPath($ModulePath)
$moduleRoot = Split-Path $ModulePath -Parent
$functionsRoot = Join-Path $moduleRoot 'Functions'
$deployScript = Join-Path $moduleRoot 'deploy.ps1'
$builtManifest = Join-Path $moduleRoot 'PowerNetbox' 'PowerNetbox.psd1'

Write-Host "Module root : $moduleRoot"
Write-Host "Functions   : $functionsRoot"
Write-Host "Built PSD1  : $builtManifest"

if (-not (Test-Path $functionsRoot)) {
    throw "Functions directory not found at '$functionsRoot'. Ensure -ModulePath points to the correct PowerNetbox.psd1."
}

# Build cmdlet-name -> relative subpath map by scanning source .ps1 files.
# e.g. Functions/DCIM/Devices/Get-NBDCIMDevice.ps1  -> 'DCIM/Devices'
Write-Host 'Building cmdlet -> subpath hashmap from source files...'
$cmdletSubpathMap = @{}
$sourceFiles = Get-ChildItem -Path $functionsRoot -Recurse -Filter '*.ps1'
foreach ($sourceFile in $sourceFiles) {
    $cmdletName = [System.IO.Path]::GetFileNameWithoutExtension($sourceFile.FullName)
    # Compute relative path from functionsRoot to the file's parent directory
    $fileDir = $sourceFile.DirectoryName
    $relDir = $fileDir.Substring($functionsRoot.Length).TrimStart([char]'/', [char]'\', [char][System.IO.Path]::DirectorySeparatorChar)
    # Normalise to forward slashes for consistency
    $relDir = $relDir -replace '\\', '/'
    if ($cmdletSubpathMap.ContainsKey($cmdletName)) {
        Write-Warning "Duplicate source filename '$cmdletName' found in '$relDir' and '$($cmdletSubpathMap[$cmdletName])'. The latter path wins."
    }
    $cmdletSubpathMap[$cmdletName] = $relDir
}
Write-Host "  $($cmdletSubpathMap.Count) source files indexed."

# ---------------------------------------------------------------------------
# 4. Build / import the module
# ---------------------------------------------------------------------------
# Always rebuild to ensure the built artifact is current.
Write-Host 'Building PowerNetbox module (deploy.ps1 -Environment dev -SkipVersion)...'
Push-Location $moduleRoot
try {
    $LASTEXITCODE = 0
    & $deployScript -Environment dev -SkipVersion | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "deploy.ps1 exited with code $LASTEXITCODE. Build failed."
    }
} finally {
    Pop-Location
}

$moduleName = 'PowerNetbox'
Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
Write-Host "Importing built module from $builtManifest ..."
Import-Module $builtManifest -Force -DisableNameChecking

$importedCount = (Get-Command -Module $moduleName -CommandType Function).Count
if ($importedCount -eq 0) {
    throw "Module '$moduleName' imported but exported 0 functions. Check the build output."
}
Write-Host "  Imported $importedCount functions."

# ---------------------------------------------------------------------------
# 5. Select cmdlets for the requested scope
# ---------------------------------------------------------------------------
$allCmdlets = Get-Command -Module $moduleName -CommandType Function | Sort-Object Name

if ($Scope -eq 'Public') {
    $targetCmdlets = $allCmdlets | Where-Object { $_.Name -match '^[A-Z][a-z]+-NB' }
} else {
    $targetCmdlets = $allCmdlets | Where-Object { $_.Name -notmatch '^[A-Z][a-z]+-NB' }
}

Write-Host "$($targetCmdlets.Count) cmdlets selected for scope '$Scope'."

# ---------------------------------------------------------------------------
# 6. Ensure output root exists
# ---------------------------------------------------------------------------
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

# ---------------------------------------------------------------------------
# 7. Generate one .md per cmdlet
# ---------------------------------------------------------------------------
$generated = 0
$skipped = 0

foreach ($cmd in $targetCmdlets) {
    $subpath = $cmdletSubpathMap[$cmd.Name]
    if ($null -eq $subpath -or $subpath -eq '') {
        Write-Warning "No source file found for '$($cmd.Name)' - skipping."
        $skipped++
        continue
    }

    $cmdletOutputDir = Join-Path $OutputPath $subpath
    New-Item -Path $cmdletOutputDir -ItemType Directory -Force | Out-Null

    # platyPS writes <CommandName>.md into the output folder
    try {
        New-MarkdownHelp -Command $cmd.Name `
                         -OutputFolder $cmdletOutputDir `
                         -Force `
                         -NoMetadata | Out-Null
    } catch {
        Write-Warning "platyPS failed for '$($cmd.Name)': $_"
        $skipped++
        continue
    }

    $mdFile = Join-Path $cmdletOutputDir "$($cmd.Name).md"
    if (Test-Path $mdFile) {
        Invoke-SnippetInjection -FilePath $mdFile -CmdletName $cmd.Name
        $generated++
    } else {
        Write-Warning "Expected file not found after generation: $mdFile"
        $skipped++
    }
}

Write-Host "Done. Generated: $generated  Skipped: $skipped"
