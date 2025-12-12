[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path $PSScriptRoot ".." "PowerNetbox" "PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "DCIM Platforms Tests" -Tag 'DCIM', 'platforms' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method'      = $Method
                'Uri'         = $Uri
                'Headers'     = $Headers
                'Timeout'     = $Timeout
                'ContentType' = $ContentType
                'Body'        = $Body
            }
        }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Get-NBDCIMPlatform" {
        It "Should request the default number of platforms" {
            $Result = Get-NBDCIMPlatform
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'
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
            # Module doesn't URL-encode spaces in query strings
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/platforms/?name=Windows Server 2016'
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
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 2 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'GET', 'GET'
        }
    }
}
