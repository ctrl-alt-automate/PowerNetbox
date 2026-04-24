<#
.SYNOPSIS
    One-time backfill of `AddedInVersion:` in comment-based help .NOTES blocks
    for all PowerNetbox functions, based on git-log analysis of the first
    release tag each file appeared in.

.DESCRIPTION
    Intended to be run once, reviewed, and committed. After the initial run,
    the `AddedInVersion:` line becomes part of the comment-based help
    convention for new functions.

.PARAMETER Path
    Root directory to scan for .ps1 files. Defaults to Functions/.

.PARAMETER DryRun
    When set, reports what would change without writing.

.EXAMPLE
    ./scripts/Backfill-AddedInVersion.ps1 -Path Functions/ -DryRun
#>
[CmdletBinding()]
param(
    [string]$Path = 'Functions/',
    [switch]$DryRun
)

function global:Find-EarliestTagForFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$FilePath)

    $firstCommit = git log --follow --diff-filter=A --format='%H' -- $FilePath 2>$null |
        Select-Object -Last 1
    if (-not $firstCommit) { return $null }

    $tag = git tag --contains $firstCommit --sort=version:refname 2>$null |
        Where-Object { $_ -match '^v?\d+\.\d+\.\d+' } |
        Select-Object -First 1

    if (-not $tag) {
        # File's first commit isn't in any tag yet -- uses current .psd1 version
        $psd1Path = Join-Path $PSScriptRoot '..' 'PowerNetbox.psd1'
        if (Test-Path $psd1Path) {
            $psd1 = Get-Content $psd1Path -Raw
            if ($psd1 -match "ModuleVersion\s*=\s*'([^']+)'") {
                return "v$($matches[1])"
            }
        }
        return $null
    }

    return $tag
}

function global:Insert-AddedInVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$CommentHelp,
        [Parameter(Mandatory)] [string]$Version,
        [string]$Newline = "`r`n"
    )

    if ($CommentHelp -match 'AddedInVersion:') { return $CommentHelp }

    if ($CommentHelp -match '\.NOTES') {
        $CommentHelp = $CommentHelp -replace '(\.NOTES[ \t]*\r?\n)', "`$1    AddedInVersion: $Version$Newline"
        return $CommentHelp
    }

    $notesBlock = "${Newline}.NOTES${Newline}    AddedInVersion: $Version${Newline}"
    $CommentHelp = $CommentHelp -replace '(\s*#>)', "$notesBlock`$1"
    return $CommentHelp
}

# Main
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "Scanning $Path for .ps1 files..."
    $files = Get-ChildItem -Path $Path -Recurse -Filter '*.ps1' -File

    $updated = 0; $skipped = 0
    foreach ($file in $files) {
        $version = Find-EarliestTagForFile -FilePath $file.FullName
        if (-not $version) {
            Write-Warning "No tag found for $($file.FullName)"
            $skipped++; continue
        }

        $content = Get-Content $file.FullName -Raw
        if ($content -notmatch '(?s)(<#.*?#>)') {
            Write-Warning "No comment help in $($file.FullName)"
            $skipped++; continue
        }

        $originalBlock = $matches[1]

        # Detect the file's line-ending convention and pass it to Insert-AddedInVersion
        $newline = if ($content -match '\r\n') { "`r`n" } else { "`n" }

        $newBlock = Insert-AddedInVersion -CommentHelp $originalBlock -Version $version -Newline $newline
        if ($originalBlock -eq $newBlock) { $skipped++; continue }

        if ($DryRun) {
            Write-Host "[dry-run] $($file.FullName) -> $version"
        } else {
            $newContent = $content.Replace($originalBlock, $newBlock)
            [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.UTF8Encoding]::new($false))
            Write-Host "$($file.FullName) -> $version"
        }
        $updated++
    }

    $updateLabel = if ($DryRun) { 'would update' } else { 'updated' }
    Write-Host "`nSummary: $updated $updateLabel, $skipped skipped."
}
