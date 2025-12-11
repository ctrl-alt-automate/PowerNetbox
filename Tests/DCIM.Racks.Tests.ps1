[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

Import-Module Pester
Remove-Module NetboxPS -Force -ErrorAction SilentlyContinue

$ModulePath = Join-Path $PSScriptRoot ".." "NetboxPS" "NetboxPS.psd1"

if (Test-Path $ModulePath) {
    Import-Module $ModulePath -ErrorAction Stop
}

Describe "DCIM Racks Tests" -Tag 'DCIM', 'Racks' {
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
        Context "Get-NBDCIMRack" {
            It "Should request racks" {
                $Result = Get-NBDCIMRack

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/'
            }

            It "Should request racks by site" {
                $Result = Get-NBDCIMRack -Site_Id 1

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/?site_id=1'
            }
        }

        Context "New-NBDCIMRack" {
            It "Should create a new rack" {
                $Result = New-NBDCIMRack -Name "Rack01" -Site 1

                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/'
                $Result.Body | Should -Match '"name":"Rack01"'
                $Result.Body | Should -Match '"site":1'
            }
        }

        Mock -CommandName "Get-NBDCIMRack" -ModuleName NetboxPS -MockWith {
            return [pscustomobject]@{
                'Id'   = $Id
                'Name' = $Name
            }
        }

        Context "Set-NBDCIMRack" {
            It "Should update a rack" {
                $Result = Set-NBDCIMRack -Id 1 -Name 'UpdatedRack' -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMRack' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/racks/1/'
            }
        }

        Context "Remove-NBDCIMRack" {
            It "Should remove a rack" {
                $Result = Remove-NBDCIMRack -Id 10 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMRack' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/racks/10/'
            }
        }
    }
}
