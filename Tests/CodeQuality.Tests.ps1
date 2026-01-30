BeforeAll {
    . "$PSScriptRoot/common.ps1"
}

Describe "Code Quality Tests" -Tag 'Quality' {

    Context "Parameter Type Validation" {

        It "Get- function Id parameters should accept arrays (uint64[])" {
            $functionsPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Functions'
            # Only check Get- functions - they should support array Id for batch queries
            # Set/Remove/other action functions operate on single resources
            $files = Get-ChildItem -Path $functionsPath -Filter "Get-*.ps1" -Recurse

            $violations = @()

            foreach ($file in $files) {
                $content = Get-Content $file.FullName -Raw

                # Check for non-array [uint64]$Id parameter declarations
                # This pattern matches [uint64]$Id followed by comma, whitespace, or newline
                if ($content -match '\[uint64\]\$Id[,\s\r\n]' -and $content -notmatch '\[uint64\[\]\]\$Id') {
                    $violations += $file.Name
                }
            }

            $violations | Should -BeNullOrEmpty -Because "Get- function Id parameters should use [uint64[]] to accept arrays. Violations: $($violations -join ', ')"
        }
    }

    Context "Function Definition Validation" {

        It "No duplicate function names should exist" {
            $functionsPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Functions'
            $files = Get-ChildItem -Path $functionsPath -Filter "*.ps1" -Recurse

            $functionNames = @{}
            $duplicates = @()

            foreach ($file in $files) {
                $content = Get-Content $file.FullName -Raw

                # Extract function name using regex
                if ($content -match 'function\s+([\w-]+)\s*\{') {
                    $funcName = $Matches[1]

                    # Case-insensitive check (PowerShell functions are case-insensitive)
                    $funcNameLower = $funcName.ToLower()
                    if ($functionNames.ContainsKey($funcNameLower)) {
                        $duplicates += [PSCustomObject]@{
                            Name  = $funcName
                            File1 = $functionNames[$funcNameLower]
                            File2 = $file.Name
                        }
                    }
                    else {
                        $functionNames[$funcNameLower] = $file.Name
                    }
                }
            }

            $duplicates | Should -BeNullOrEmpty -Because "Each function should only be defined once"
        }
    }
}
