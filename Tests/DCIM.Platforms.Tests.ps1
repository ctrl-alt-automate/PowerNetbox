
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
)
Import-Module Pester
Remove-Module NetboxPSv4 -Force -ErrorAction SilentlyContinue

$ModulePath = Join-Path $PSScriptRoot ".." "NetboxPSv4" "NetboxPSv4.psd1"

if (Test-Path $ModulePath) {
    Import-Module $ModulePath -ErrorAction Stop
}

Describe "DCIM Platforms Tests" -Tag 'DCIM', 'platforms' {
    Mock -CommandName 'CheckNetboxIsConnected' -Verifiable -ModuleName 'NetboxPSv4' -MockWith {
        return $true
    }

    Mock -CommandName 'Invoke-RestMethod' -Verifiable -ModuleName 'NetboxPSv4' -MockWith {
        # Return a hashtable of the items we would normally pass to Invoke-RestMethod
        return [ordered]@{
            'Method'      = $Method
            'Uri'         = $Uri
            'Headers'     = $Headers
            'Timeout'     = $Timeout
            'ContentType' = $ContentType
            'Body'        = $Body
        }
    }

    Mock -CommandName 'Get-NBCredential' -Verifiable -ModuleName 'NetboxPSv4' -MockWith {
        return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
    }

    Mock -CommandName 'Get-NBHostname' -Verifiable -ModuleName 'NetboxPSv4' -MockWith {
        return 'netbox.domain.com'
    }

    InModuleScope -ModuleName 'NetboxPSv4' -ScriptBlock {
        Context "Get-NBDCIMPlatform" {
            It "Should request the default number of platforms" {
                $Result = Get-NBDCIMPlatform

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/platforms/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a limit and offset" {
                $Result = Get-NBDCIMPlatform -Limit 10 -Offset 100

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/platforms/?offset=100&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a platform name" {
                $Result = Get-NBDCIMPlatform -Name "Windows Server 2016"

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/platforms/?name=Windows+Server+2016'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a platform by manufacturer" {
                $Result = Get-NBDCIMPlatform -Manufacturer 'Cisco'

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/platforms/?manufacturer=Cisco'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a platform by ID" {
                $Result = Get-NBDCIMPlatform -Id 10

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/platforms/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request multiple platforms by ID" {
                $Result = Get-NBDCIMPlatform -Id 10, 20

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET', 'GET'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/platforms/10/', 'https://netbox.domain.com/api/dcim/platforms/20/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }
        }
    }
}




