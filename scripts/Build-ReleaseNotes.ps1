<#
.SYNOPSIS
    Fetches GitHub release notes for PowerNetbox and writes one Markdown file
    per release, plus an index.md that groups them all.

.DESCRIPTION
    Calls 'gh api repos/<Repo>/releases?per_page=100' to retrieve all releases,
    filters to semver-shaped tags, and writes per-release Markdown pages plus
    an index to -OutputPath.  The files are written as UTF-8-without-BOM so
    they work correctly on both PowerShell 5.1 (Windows) and PowerShell 7+.

.PARAMETER OutputPath
    Directory where the Markdown files are written.  Created if it does not
    already exist.

.PARAMETER Repo
    GitHub repository slug (owner/name).  Defaults to the PowerNetbox repo.

.EXAMPLE
    ./Build-ReleaseNotes.ps1 -OutputPath ./docs/release-notes
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OutputPath,

    [string]$Repo = 'ctrl-alt-automate/PowerNetbox'
)

# Ensure output directory exists
New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null

# --- Fetch releases ---
Write-Host "Fetching releases for $Repo..."
# Fetch releases. per_page=100 is sufficient for PowerNetbox's ~25 releases.
# If the count ever approaches 100, implement cursor-based pagination here.
$releasesJson = gh api "repos/$Repo/releases?per_page=100" 2>$null
if (-not $releasesJson) {
    throw "Failed to fetch releases for $Repo. Verify 'gh auth status' and network connectivity."
}

$releases = $releasesJson | ConvertFrom-Json

# Keep only semver-shaped tags (3-part or 4-part, with optional leading 'v')
$releases = @($releases | Where-Object { $_.tag_name -match '^v?\d+\.\d+\.\d+(\.\d+)?$' })

if ($releases.Count -eq 0) {
    throw "No semver releases found for $Repo."
}

Write-Host "Processing $($releases.Count) releases..."

# UTF-8 without BOM encoder for PS 5.1 / PS 7 compat
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$indexEntries = @()

foreach ($release in $releases) {
    $version = $release.tag_name -replace '^v', ''
    $slug    = $version

    $dateStr = if ($release.published_at) {
        ([datetime]$release.published_at).ToString('yyyy-MM-dd')
    } else {
        'unreleased'
    }

    $body = if ($release.body) { $release.body } else { '(no release notes provided)' }

    $pageContent = @"
---
title: "v$version - $dateStr"
---

# PowerNetbox v$version

Released $dateStr - [View on GitHub](https://github.com/$Repo/releases/tag/$($release.tag_name))

$body
"@

    $pagePath = Join-Path $OutputPath "$slug.md"
    [System.IO.File]::WriteAllText($pagePath, $pageContent, $utf8NoBom)

    $indexEntries += [pscustomobject]@{
        Version = $version
        Date    = $dateStr
        Slug    = $slug
        Tag     = $release.tag_name
    }
}

# --- Build index.md ---
$indexContent = @"
---
title: "Release Notes"
---

# Release Notes

Every PowerNetbox release, newest first. Each page mirrors the GitHub Release
notes for that tag.

"@

foreach ($entry in $indexEntries) {
    $indexContent += "`n## [v$($entry.Version)]($($entry.Slug).md) - $($entry.Date)`n"
}

[System.IO.File]::WriteAllText((Join-Path $OutputPath 'index.md'), $indexContent, $utf8NoBom)

# Write awesome-pages .pages file with explicit descending-semver nav order.
# Without this, awesome-pages sorts alphabetically (so 4.4.10 ends up above 4.4.7).
$sortedEntries = $indexEntries | Sort-Object { [version]$_.Version } -Descending
$pagesLines = @('nav:', '  - index.md')
foreach ($entry in $sortedEntries) {
    $pagesLines += "  - $($entry.Slug).md"
}
$pagesContent = ($pagesLines -join "`n") + "`n"
[System.IO.File]::WriteAllText(
    (Join-Path $OutputPath '.pages'),
    $pagesContent,
    [System.Text.UTF8Encoding]::new($false)
)
Write-Host "Wrote release-notes/.pages (descending semver order)"

Write-Host "Wrote $($indexEntries.Count) release pages + index.md to $OutputPath"
