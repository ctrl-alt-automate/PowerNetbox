<#
.SYNOPSIS
    Tests for Add-OmitParameter.ps1 script

.DESCRIPTION
    Comprehensive tests to ensure the Add-OmitParameter script:
    1. Correctly identifies files needing updates
    2. Skips files that already have -Omit
    3. Makes syntactically correct modifications
    4. Preserves file integrity
    5. Modified files still parse correctly
#>

BeforeAll {
    $ScriptPath = Join-Path $PSScriptRoot "Add-OmitParameter.ps1"

    # Create test directory (cross-platform temp path)
    $tempBase = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
    $script:TestDir = Join-Path $tempBase "OmitParameterTests_$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
}

AfterAll {
    # Cleanup test directory
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force
    }
}

Describe "Add-OmitParameter Script Tests" {

    Context "File Detection" {

        It "Should identify files that need -Omit parameter" {
            # Create test file WITH $Fields but WITHOUT $Omit
            $testFile = Join-Path $script:TestDir "Get-NBTestFunction.ps1"
            @'
function Get-NBTestFunction {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            $files = Get-FilesNeedingOmit -Path $script:TestDir

            $files | Should -Contain $testFile
        }

        It "Should skip files that already have -Omit parameter" {
            $testFile = Join-Path $script:TestDir "Get-NBAlreadyHasOmit.ps1"
            @'
function Get-NBAlreadyHasOmit {
    param(
        [string[]]$Fields,
        [string[]]$Omit,
        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            $files = Get-FilesNeedingOmit -Path $script:TestDir

            $files | Should -Not -Contain $testFile
        }

        It "Should skip files without -Fields parameter" {
            $testFile = Join-Path $script:TestDir "Get-NBNoFields.ps1"
            @'
function Get-NBNoFields {
    param(
        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            $files = Get-FilesNeedingOmit -Path $script:TestDir

            $files | Should -Not -Contain $testFile
        }

        It "Should only process Get-NB*.ps1 files" {
            $testFile = Join-Path $script:TestDir "Set-NBTestFunction.ps1"
            @'
function Set-NBTestFunction {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            $files = Get-FilesNeedingOmit -Path $script:TestDir

            $files | Should -Not -Contain $testFile
        }
    }

    Context "Parameter Insertion" {

        It "Should insert -Omit parameter after -Fields parameter" {
            $testFile = Join-Path $script:TestDir "Get-NBInsertTest.ps1"
            $originalContent = @'
function Get-NBInsertTest {
    param(
        [string[]]$Fields,

        [switch]$Raw
    )
}
'@
            $originalContent | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newContent = Get-Content -Path $testFile -Raw

            # Verify -Omit is present
            $newContent | Should -Match '\[string\[\]\]\$Omit'

            # Verify -Omit comes after -Fields
            $fieldsIndex = $newContent.IndexOf('$Fields')
            $omitIndex = $newContent.IndexOf('$Omit')
            $omitIndex | Should -BeGreaterThan $fieldsIndex
        }

        It "Should handle param block with trailing comma after Fields" {
            $testFile = Join-Path $script:TestDir "Get-NBTrailingComma.ps1"
            @'
function Get-NBTrailingComma {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newContent = Get-Content -Path $testFile -Raw
            $newContent | Should -Match '\[string\[\]\]\$Omit'
        }

        It "Should preserve original indentation" {
            $testFile = Join-Path $script:TestDir "Get-NBIndentation.ps1"
            @'
function Get-NBIndentation {
    param(
        [string[]]$Fields,

        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $lines = Get-Content -Path $testFile
            $omitLine = $lines | Where-Object { $_ -match '\$Omit' }

            # Should have same indentation as $Fields line (8 spaces)
            $omitLine | Should -Match '^\s{8}\[string\[\]\]\$Omit'
        }
    }

    Context "Documentation Insertion" {

        It "Should add .PARAMETER Omit documentation" {
            $testFile = Join-Path $script:TestDir "Get-NBDocTest.ps1"
            @'
<#
.SYNOPSIS
    Test function

.PARAMETER Fields
    Field selection.

.PARAMETER Raw
    Return raw response.
#>
function Get-NBDocTest {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newContent = Get-Content -Path $testFile -Raw
            $newContent | Should -Match '\.PARAMETER Omit'
            $newContent | Should -Match 'Netbox 4\.5'
        }

        It "Should add .PARAMETER Omit after .PARAMETER Fields" {
            $testFile = Join-Path $script:TestDir "Get-NBDocOrder.ps1"
            @'
<#
.PARAMETER Fields
    Field selection.

.PARAMETER Raw
    Return raw response.
#>
function Get-NBDocOrder {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newContent = Get-Content -Path $testFile -Raw
            $fieldsDocIndex = $newContent.IndexOf('.PARAMETER Fields')
            $omitDocIndex = $newContent.IndexOf('.PARAMETER Omit')
            $rawDocIndex = $newContent.IndexOf('.PARAMETER Raw')

            $omitDocIndex | Should -BeGreaterThan $fieldsDocIndex
            $omitDocIndex | Should -BeLessThan $rawDocIndex
        }
    }

    Context "File Integrity" {

        It "Should produce valid PowerShell syntax" {
            $testFile = Join-Path $script:TestDir "Get-NBSyntaxTest.ps1"
            @'
<#
.SYNOPSIS
    Test function
.PARAMETER Fields
    Fields to include.
.PARAMETER Raw
    Raw output.
#>
function Get-NBSyntaxTest {
    [CmdletBinding()]
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
    process {
        Write-Output "Test"
    }
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            # Parse the file - should not throw
            $errors = $null
            $tokens = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $testFile,
                [ref]$tokens,
                [ref]$errors
            )

            $errors | Should -BeNullOrEmpty
        }

        It "Should not corrupt files with special characters" {
            $testFile = Join-Path $script:TestDir "Get-NBSpecialChars.ps1"
            @'
<#
.SYNOPSIS
    Test with special chars: é, ñ, ü
.PARAMETER Fields
    Fields to include.
#>
function Get-NBSpecialChars {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
    # Comment with special: © ® ™
}
'@ | Set-Content -Path $testFile -Encoding UTF8

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newContent = Get-Content -Path $testFile -Raw
            $newContent | Should -Match 'é, ñ, ü'
            $newContent | Should -Match '© ® ™'
        }

        It "Should preserve BOM if present" {
            $testFile = Join-Path $script:TestDir "Get-NBBOM.ps1"
            $content = @'
function Get-NBBOM {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
}
'@
            # Write with BOM
            [System.IO.File]::WriteAllText($testFile, $content, [System.Text.UTF8Encoding]::new($true))

            $originalBytes = [System.IO.File]::ReadAllBytes($testFile)
            $hadBOM = ($originalBytes[0] -eq 0xEF -and $originalBytes[1] -eq 0xBB -and $originalBytes[2] -eq 0xBF)

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newBytes = [System.IO.File]::ReadAllBytes($testFile)
            $hasBOM = ($newBytes[0] -eq 0xEF -and $newBytes[1] -eq 0xBB -and $newBytes[2] -eq 0xBF)

            $hasBOM | Should -Be $hadBOM
        }
    }

    Context "Idempotency" {

        It "Should not modify file if run twice" {
            $testFile = Join-Path $script:TestDir "Get-NBIdempotent.ps1"
            @'
function Get-NBIdempotent {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile
            $firstContent = Get-Content -Path $testFile -Raw

            Add-OmitParameter -FilePath $testFile
            $secondContent = Get-Content -Path $testFile -Raw

            $secondContent | Should -BeExactly $firstContent
        }
    }

    Context "Edge Cases" {

        It "Should handle files with multiple param blocks (nested functions)" {
            $testFile = Join-Path $script:TestDir "Get-NBNestedFunctions.ps1"
            @'
function Get-NBNestedFunctions {
    param(
        [string[]]$Fields,
        [switch]$Raw
    )

    # Helper function inside
    function InnerHelper {
        param([string]$Value)
    }
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newContent = Get-Content -Path $testFile -Raw

            # Should only have ONE $Omit
            $omitCount = ([regex]::Matches($newContent, '\$Omit')).Count
            $omitCount | Should -Be 1
        }

        It "Should handle different line endings (CRLF vs LF)" {
            $testFile = Join-Path $script:TestDir "Get-NBLineEndings.ps1"
            $content = "function Get-NBLineEndings {`r`n    param(`r`n        [string[]]`$Fields,`r`n        [switch]`$Raw`r`n    )`r`n}"
            [System.IO.File]::WriteAllText($testFile, $content)

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newContent = Get-Content -Path $testFile -Raw
            $newContent | Should -Match '\[string\[\]\]\$Omit'

            # Should preserve CRLF
            $newContent | Should -Match "`r`n"
        }
    }

    Context "Real-World Sample" {

        It "Should correctly modify a real Get function pattern" {
            $testFile = Join-Path $script:TestDir "Get-NBDCIMSite.ps1"
            @'
<#
.SYNOPSIS
    Retrieves Site objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Site objects from Netbox DCIM module.

.PARAMETER All
    Automatically fetch all pages of results.

.PARAMETER Brief
    Return minimal representation.

.PARAMETER Fields
    Specify which fields to include in the response.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBDCIMSite

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMSite {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving DCIM Site"
        # ... implementation
    }
}
'@ | Set-Content -Path $testFile

            . $ScriptPath
            Add-OmitParameter -FilePath $testFile

            $newContent = Get-Content -Path $testFile -Raw

            # Verify all requirements
            $newContent | Should -Match '\[string\[\]\]\$Omit'
            $newContent | Should -Match '\.PARAMETER Omit'
            $newContent | Should -Match 'Netbox 4\.5'

            # Parse check
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $testFile,
                [ref]$null,
                [ref]$errors
            )
            $errors | Should -BeNullOrEmpty

            # Verify parameter order in AST
            $funcDef = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)[0]
            $params = $funcDef.Body.ParamBlock.Parameters.Name.VariablePath.UserPath

            $fieldsIndex = [array]::IndexOf($params, 'Fields')
            $omitIndex = [array]::IndexOf($params, 'Omit')

            $omitIndex | Should -Be ($fieldsIndex + 1)
        }
    }
}
