#Requires -Modules Pester
BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Build-PlatyPSReference.ps1'
    $script:TempDir = Join-Path ([System.IO.Path]::GetTempPath()) "platyps-test-$(Get-Random)"
    New-Item -Path $script:TempDir -ItemType Directory -Force | Out-Null
}

AfterAll {
    if (Test-Path $script:TempDir) { Remove-Item $script:TempDir -Recurse -Force }
}

Describe 'Build-PlatyPSReference.ps1' {
    It 'exists and is a runnable script' {
        Test-Path $script:ScriptPath | Should -BeTrue
    }

    It 'accepts -ModulePath and -OutputPath parameters' {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:ScriptPath, [ref]$null, [ref]$null)
        $params = $ast.ParamBlock.Parameters.Name.VariablePath.UserPath
        $params | Should -Contain 'ModulePath'
        $params | Should -Contain 'OutputPath'
    }

    It 'produces one .md file per exported public cmdlet' {
        & $script:ScriptPath -ModulePath (Join-Path $PSScriptRoot '..' 'PowerNetbox.psd1') `
                             -OutputPath $script:TempDir `
                             -Scope Public
        $generatedFiles = Get-ChildItem -Path $script:TempDir -Recurse -Filter '*.md'
        # PowerNetbox has 450+ public cmdlets
        $generatedFiles.Count | Should -BeGreaterThan 400
    }

    It 'groups reference pages by module/endpoint matching source structure' {
        & $script:ScriptPath -ModulePath (Join-Path $PSScriptRoot '..' 'PowerNetbox.psd1') `
                             -OutputPath $script:TempDir `
                             -Scope Public
        # Get-NBDCIMDevice should land in DCIM/Devices/
        Test-Path (Join-Path $script:TempDir 'DCIM' 'Devices' 'Get-NBDCIMDevice.md') |
            Should -BeTrue
    }

    It 'uses the custom template with snippet-include markers' {
        & $script:ScriptPath -ModulePath (Join-Path $PSScriptRoot '..' 'PowerNetbox.psd1') `
                             -OutputPath $script:TempDir `
                             -Scope Public
        $content = Get-Content -Raw (Join-Path $script:TempDir 'DCIM' 'Devices' 'Get-NBDCIMDevice.md')
        # Pagination params snippet should be referenced on Get- cmdlets
        $content | Should -Match '--8<-- "common-pagination-params\.md"'
    }
}
