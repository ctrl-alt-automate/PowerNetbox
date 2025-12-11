[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

Import-Module Pester
Remove-Module NetboxPS -Force -ErrorAction SilentlyContinue

$ModulePath = Join-Path $PSScriptRoot ".." "NetboxPS" "NetboxPS.psd1"

if (Test-Path $ModulePath) {
    Import-Module $ModulePath -ErrorAction Stop
}

Describe "DCIM Sites Tests" -Tag 'DCIM', 'Sites' {
    Mock -CommandName 'CheckNetboxIsConnected' -Verifiable -ModuleName 'NetboxPS' -MockWith {
        return $true
    }

    Mock -CommandName 'Invoke-RestMethod' -Verifiable -ModuleName 'NetboxPS' -MockWith {
        return [ordered]@{
            'Method'      = $Method
            'Uri'         = $Uri
            'Headers'     = $Headers
            'Timeout'     = $Timeout
            'ContentType' = $ContentType
            'Body'        = $Body
        }
    }

    Mock -CommandName 'Get-NBCredential' -Verifiable -ModuleName 'NetboxPS' -MockWith {
        return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
    }

    Mock -CommandName 'Get-NBHostname' -Verifiable -ModuleName 'NetboxPS' -MockWith {
        return 'netbox.domain.com'
    }

    InModuleScope -ModuleName 'NetboxPS' -ScriptBlock {
        Context "Get-NBDCIMSite" {
            It "Should request sites" {
                $Result = Get-NBDCIMSite

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/'
            }

            It "Should request a site by name" {
                $Result = Get-NBDCIMSite -Name 'TestSite'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/?name=TestSite'
            }

            It "Should request a site by ID" {
                $Result = Get-NBDCIMSite -Id 5

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/5/'
            }
        }

        Context "New-NBDCIMSite" {
            It "Should create a new site" {
                $Result = New-NBDCIMSite -Name "NewSite" -Slug "newsite"

                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/'
                $Result.Body | Should -Match '"name":"NewSite"'
                $Result.Body | Should -Match '"slug":"newsite"'
            }
        }

        Mock -CommandName "Get-NBDCIMSite" -ModuleName NetboxPS -MockWith {
            return [pscustomobject]@{
                'Id'   = $Id
                'Name' = $Name
            }
        }

        Context "Set-NBDCIMSite" {
            It "Should update a site" {
                $Result = Set-NBDCIMSite -Id 1 -Name 'UpdatedSite' -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMSite' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/sites/1/'
                $Result.Body | Should -Match '"name":"UpdatedSite"'
            }
        }

        Context "Remove-NBDCIMSite" {
            It "Should remove a site" {
                $Result = Remove-NBDCIMSite -Id 10 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMSite' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/sites/10/'
            }
        }
    }
}
