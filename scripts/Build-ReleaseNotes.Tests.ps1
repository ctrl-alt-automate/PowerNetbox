BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Build-ReleaseNotes.ps1'
    $script:TempDir = Join-Path ([System.IO.Path]::GetTempPath()) "releasenotes-test-$(Get-Random)"
    New-Item -Path $script:TempDir -ItemType Directory -Force | Out-Null
}

AfterAll {
    if (Test-Path $script:TempDir) { Remove-Item $script:TempDir -Recurse -Force }
}

Describe 'Build-ReleaseNotes.ps1' {
    It 'accepts -OutputPath parameter' {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:ScriptPath, [ref]$null, [ref]$null)
        $params = $ast.ParamBlock.Parameters.Name.VariablePath.UserPath
        $params | Should -Contain 'OutputPath'
    }

    It 'produces one .md file per GitHub release' {
        & $script:ScriptPath -OutputPath $script:TempDir
        $files = Get-ChildItem -Path $script:TempDir -Filter '*.md' -Recurse
        # PowerNetbox has 25+ releases; expect at least 5
        $files.Count | Should -BeGreaterThan 5
    }

    It 'produces an index.md grouping releases' {
        & $script:ScriptPath -OutputPath $script:TempDir
        Test-Path (Join-Path $script:TempDir 'index.md') | Should -BeTrue
    }

    It 'release pages use the tag as slug' {
        & $script:ScriptPath -OutputPath $script:TempDir
        # Accept 3-part (v4.4.7) and 4-part (v4.5.8.1) semver slugs
        $files = Get-ChildItem -Path $script:TempDir -Filter '*.md' | Where-Object { $_.Name -ne 'index.md' }
        $files | ForEach-Object { $_.BaseName | Should -Match '^\d+\.\d+\.\d+(\.\d+)?$' }
    }
}
