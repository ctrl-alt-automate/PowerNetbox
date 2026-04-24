BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Backfill-AddedInVersion.ps1'
}

Describe 'Backfill-AddedInVersion.ps1' {
    It 'exists' {
        Test-Path $script:ScriptPath | Should -BeTrue
    }

    It 'accepts -Path and -DryRun parameters' {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $script:ScriptPath, [ref]$null, [ref]$null)
        $params = $ast.ParamBlock.Parameters.Name.VariablePath.UserPath
        $params | Should -Contain 'Path'
        $params | Should -Contain 'DryRun'
    }

    Context 'Find-EarliestTagForFile helper' {
        BeforeAll {
            . $script:ScriptPath  # dot-source for helper access; script must support this
        }

        It 'returns the earliest semver tag where a file first appeared' {
            # Connect-NBAPI has been in the project since the fork; should map to a known early tag
            $result = Find-EarliestTagForFile -FilePath 'Functions/Setup/Connect-NBAPI.ps1'
            $result | Should -Match '^v?\d+\.\d+\.\d+'
        }

        It 'returns $null for a non-existent file' {
            $result = Find-EarliestTagForFile -FilePath 'Functions/Nonexistent.ps1'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Insert-AddedInVersion helper' {
        It 'adds the AddedInVersion line to a .NOTES section that lacks it' {
            $input = @'
<#
.SYNOPSIS
    Foo
.NOTES
    Some existing note.
#>
'@
            $result = Insert-AddedInVersion -CommentHelp $input -Version 'v4.5.7'
            $result | Should -Match 'AddedInVersion:\s+v4\.5\.7'
            $result | Should -Match 'Some existing note\.'   # preserves existing
        }

        It 'does not duplicate AddedInVersion when already present' {
            $input = @'
<#
.SYNOPSIS
    Foo
.NOTES
    AddedInVersion: v4.5.1
#>
'@
            $result = Insert-AddedInVersion -CommentHelp $input -Version 'v4.5.7'
            ([regex]::Matches($result, 'AddedInVersion:')).Count | Should -Be 1
        }

        It 'creates a .NOTES section if none exists' {
            $input = @'
<#
.SYNOPSIS
    Foo
#>
'@
            $result = Insert-AddedInVersion -CommentHelp $input -Version 'v4.5.7'
            $result | Should -Match '\.NOTES'
            $result | Should -Match 'AddedInVersion:\s+v4\.5\.7'
        }
    }
}
