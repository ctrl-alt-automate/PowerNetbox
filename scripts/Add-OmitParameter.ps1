<#
.SYNOPSIS
    Adds -Omit parameter to Get-NB* functions that have -Fields but not -Omit.

.DESCRIPTION
    This script automates adding the -Omit parameter to PowerNetbox Get functions.
    It identifies files that have the -Fields parameter but are missing -Omit,
    then adds the parameter and documentation in the correct locations.

    Can be dot-sourced to import functions, or run directly to process files.

.EXAMPLE
    .\Add-OmitParameter.ps1 -WhatIf
    Shows which files would be modified.

.EXAMPLE
    .\Add-OmitParameter.ps1
    Modifies all applicable files.

.EXAMPLE
    . .\Add-OmitParameter.ps1
    Get-FilesNeedingOmit -Path ./Functions
    Dot-source to use functions directly.
#>

function Get-FilesNeedingOmit {
    <#
    .SYNOPSIS
        Returns files that need the -Omit parameter added.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $files = Get-ChildItem -Path $Path -Filter "Get-NB*.ps1" -Recurse -File

    $needsOmit = @()

    foreach ($file in $files) {
        $content = Get-Content -Path $file.FullName -Raw

        # Must have $Fields parameter
        $hasFields = $content -match '\[string\[\]\]\$Fields'

        # Must NOT already have $Omit parameter
        $hasOmit = $content -match '\[string\[\]\]\$Omit'

        if ($hasFields -and -not $hasOmit) {
            $needsOmit += $file.FullName
        }
    }

    return $needsOmit
}

function Add-OmitParameter {
    <#
    .SYNOPSIS
        Adds -Omit parameter to a single file.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    # Read file preserving encoding
    $originalBytes = [System.IO.File]::ReadAllBytes($FilePath)
    $hasBOM = ($originalBytes.Length -ge 3 -and
               $originalBytes[0] -eq 0xEF -and
               $originalBytes[1] -eq 0xBB -and
               $originalBytes[2] -eq 0xBF)

    $content = Get-Content -Path $FilePath -Raw

    # Check if already has -Omit
    if ($content -match '\[string\[\]\]\$Omit') {
        Write-Verbose "File already has -Omit parameter: $FilePath"
        return
    }

    # Check if has -Fields
    if ($content -notmatch '\[string\[\]\]\$Fields') {
        Write-Verbose "File does not have -Fields parameter: $FilePath"
        return
    }

    # Detect line ending style
    $lineEnding = if ($content -match "`r`n") { "`r`n" } else { "`n" }

    # 1. Add parameter after $Fields in param block
    # Pattern: Find [string[]]$Fields, followed by comma and possible whitespace/newline
    $paramPattern = '(\[string\[\]\]\$Fields)(,?)(\s*)'

    # Determine indentation by looking at the $Fields line
    $fieldsMatch = [regex]::Match($content, '(?m)^(\s*)\[string\[\]\]\$Fields')
    $indent = if ($fieldsMatch.Success) { $fieldsMatch.Groups[1].Value } else { "        " }

    # Replace: Add $Omit after $Fields
    $paramReplacement = '$1,' + $lineEnding + $lineEnding + $indent + '[string[]]$Omit$2$3'
    $newContent = $content -replace $paramPattern, $paramReplacement

    # 2. Add .PARAMETER Omit documentation after .PARAMETER Fields
    $docPattern = '(\.PARAMETER Fields\s*\r?\n(?:.*?\r?\n)*?)(\s*\.PARAMETER|\s*\.EXAMPLE|\s*\.LINK|\s*#>)'

    $omitDoc = @"
`$1
.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

`$2
"@

    # Only add doc if .PARAMETER Fields exists
    if ($newContent -match '\.PARAMETER Fields') {
        $newContent = $newContent -replace $docPattern, $omitDoc
    }

    # Verify syntax before writing
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseInput(
        $newContent,
        [ref]$null,
        [ref]$errors
    )

    if ($errors) {
        Write-Error "Syntax errors would be introduced in $FilePath. Aborting."
        Write-Error ($errors | Out-String)
        return
    }

    # Write file with original encoding
    if ($PSCmdlet.ShouldProcess($FilePath, "Add -Omit parameter")) {
        $encoding = if ($hasBOM) {
            [System.Text.UTF8Encoding]::new($true)
        } else {
            [System.Text.UTF8Encoding]::new($false)
        }

        [System.IO.File]::WriteAllText($FilePath, $newContent, $encoding)
        Write-Verbose "Updated: $FilePath"
    }
}

function Invoke-AddOmitParameter {
    <#
    .SYNOPSIS
        Main entry point - processes all files needing -Omit parameter.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Path = (Join-Path $PSScriptRoot ".." "Functions")
    )

    $files = Get-FilesNeedingOmit -Path $Path

    Write-Host "Found $($files.Count) files needing -Omit parameter" -ForegroundColor Cyan

    if ($files.Count -eq 0) {
        Write-Host "No files need modification." -ForegroundColor Green
        return
    }

    $modified = 0
    foreach ($file in $files) {
        if ($PSCmdlet.ShouldProcess($file, "Add -Omit parameter")) {
            Add-OmitParameter -FilePath $file -Confirm:$false
            $modified++
        }
    }

    Write-Host "Done! Modified $modified files." -ForegroundColor Green
}

# Main execution when run directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-AddOmitParameter @args
}
