[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    $script:AuditorPath = Join-Path (Join-Path $PSScriptRoot "..") "scripts/Verify-FilterExclusion.ps1"
    if (-not (Test-Path $script:AuditorPath)) {
        throw "Auditor script not found at $script:AuditorPath"
    }

    # Per-test workspace for synthetic Get-NB*.ps1 fixtures
    $script:FixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) "pn-auditor-tests-$([Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $script:FixtureRoot -Force | Out-Null
}

AfterAll {
    if ($script:FixtureRoot -and (Test-Path $script:FixtureRoot)) {
        Remove-Item $script:FixtureRoot -Recurse -Force
    }
}

Describe "Verify-FilterExclusion.ps1 auditor" -Tag 'Unit', 'Auditor' {

    BeforeAll {
        # Helper function for creating fixture files and invoking the auditor.
        # Declared in BeforeAll so It blocks (Pester v5 isolation) can see them.
        function script:New-FixtureFile {
            param(
                [Parameter(Mandatory)][string]$Name,
                [Parameter(Mandatory)][string]$Content
            )
            $subDir = Join-Path $script:FixtureRoot ([Guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $subDir -Force | Out-Null
            $path = Join-Path $subDir "$Name.ps1"
            Set-Content -Path $path -Value $Content -Encoding UTF8
            return $subDir
        }

        function script:Invoke-Auditor {
            param([string]$Path)
            $json = & $script:AuditorPath -Path $Path -OutputFormat Json -SkipExemptions 2>&1 | Out-String
            if ([string]::IsNullOrWhiteSpace($json)) { return @() }
            return $json | ConvertFrom-Json
        }
    }

    It "Reports zero findings when the function correctly invokes AssertNBMutualExclusiveParam" {
        $content = @'
function Get-NBTestCorrect {
    param(
        [switch]$Brief,
        [string[]]$Fields,
        [string[]]$Omit
    )
    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'
        # ... rest of function
    }
}
'@
        $dir = New-FixtureFile -Name 'Get-NBTestCorrect' -Content $content
        $findings = Invoke-Auditor -Path $dir
        $findings | Should -BeNullOrEmpty
    }

    It "Reports a finding when the function declares all three but omits the assertion" {
        $content = @'
function Get-NBTestMissing {
    param(
        [switch]$Brief,
        [string[]]$Fields,
        [string[]]$Omit
    )
    process {
        Write-Verbose "Doing stuff"
    }
}
'@
        $dir = New-FixtureFile -Name 'Get-NBTestMissing' -Content $content
        $findings = Invoke-Auditor -Path $dir
        $findings.Count | Should -Be 1
        $findings[0].Function | Should -Be 'Get-NBTestMissing'
        $findings[0].Status | Should -Match 'Missing'
    }

    It "Skips the function when one of the three parameters is not declared" {
        $content = @'
function Get-NBTestOnlyTwo {
    param(
        [switch]$Brief,
        [string[]]$Fields
    )
    process {
        Write-Verbose "Doing stuff"
    }
}
'@
        $dir = New-FixtureFile -Name 'Get-NBTestOnlyTwo' -Content $content
        $findings = Invoke-Auditor -Path $dir
        $findings | Should -BeNullOrEmpty
    }

    It "Reports a finding when the assertion is inside a comment (not a real invocation)" {
        $content = @'
function Get-NBTestCommentedOut {
    param(
        [switch]$Brief,
        [string[]]$Fields,
        [string[]]$Omit
    )
    process {
        # AssertNBMutualExclusiveParam -BoundParameters $PSBoundParameters -Parameters 'Brief','Fields','Omit'
        Write-Verbose "Doing stuff"
    }
}
'@
        $dir = New-FixtureFile -Name 'Get-NBTestCommentedOut' -Content $content
        $findings = Invoke-Auditor -Path $dir
        $findings.Count | Should -Be 1
        $findings[0].Function | Should -Be 'Get-NBTestCommentedOut'
    }

    It "Reports a finding when the assertion lists the wrong parameter names" {
        $content = @'
function Get-NBTestWrongArgs {
    param(
        [switch]$Brief,
        [string[]]$Fields,
        [string[]]$Omit
    )
    process {
        AssertNBMutualExclusiveParam -BoundParameters $PSBoundParameters -Parameters 'Brief', 'Fields'
    }
}
'@
        $dir = New-FixtureFile -Name 'Get-NBTestWrongArgs' -Content $content
        $findings = Invoke-Auditor -Path $dir
        $findings.Count | Should -Be 1
        $findings[0].Function | Should -Be 'Get-NBTestWrongArgs'
    }

    It "Exits with non-zero code under -FailOnMismatch when findings exist" {
        $content = @'
function Get-NBTestFailingFast {
    param([switch]$Brief, [string[]]$Fields, [string[]]$Omit)
    process { }
}
'@
        $dir = New-FixtureFile -Name 'Get-NBTestFailingFast' -Content $content
        & $script:AuditorPath -Path $dir -FailOnMismatch -SkipExemptions -OutputFormat Json > $null 2>&1
        $LASTEXITCODE | Should -Be 1
    }
}
