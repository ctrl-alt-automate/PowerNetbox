param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "DCIM Platforms Tests" -Tag 'DCIM', 'platforms' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
        }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Get-NBDCIMPlatform" {
        It "Should request the default number of platforms" {
            $Result = Get-NBDCIMPlatform
            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/platforms/'
        }

        It "Should request with a limit and offset" {
            $Result = Get-NBDCIMPlatform -Limit 10 -Offset 100
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=100'
        }

        It "Should request with a platform name" {
            $Result = Get-NBDCIMPlatform -Name "Windows Server 2016"
            # UriBuilder encodes spaces as %20 in the URI
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/platforms/?name=Windows%20Server%202016'
        }

        It "Should request a platform by manufacturer" {
            $Result = Get-NBDCIMPlatform -Manufacturer 'Cisco'
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/platforms/?manufacturer=Cisco'
        }

        It "Should request a platform by ID" {
            $Result = Get-NBDCIMPlatform -Id 10
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/platforms/10/'
        }

        It "Should request multiple platforms by ID" {
            $Result = Get-NBDCIMPlatform -Id 10, 20
            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 2 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'GET', 'GET'
        }
    }

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBDCIMPlatform'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'Set-NBDCIMPlatform'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMPlatform'; Parameters = @{ Id = 1 } }
        )

        It 'Should support -WhatIf for <Command>' -TestCases $whatIfTestCases {
            param($Command, $Parameters)
            $splat = $Parameters.Clone()
            $splat.Add('WhatIf', $true)
            $Result = & $Command @splat
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion
}
