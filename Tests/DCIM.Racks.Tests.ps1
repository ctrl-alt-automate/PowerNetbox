[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "DCIM Racks Tests" -Tag 'DCIM', 'Racks' {
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

    Context "Get-NBDCIMRack" {
        It "Should request racks" {
            $Result = Get-NBDCIMRack
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/'
        }

        It "Should request racks by site" {
            $Result = Get-NBDCIMRack -Site_Id 1
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/?site_id=1'
        }
    }

    Context "New-NBDCIMRack" {
        It "Should create a new rack" {
            $Result = New-NBDCIMRack -Name "Rack01" -Site 1
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/'
            $Result.Body | Should -Match '"name":"Rack01"'
            $Result.Body | Should -Match '"site":1'
        }
    }

    Context "Set-NBDCIMRack" {
        It "Should update a rack" {
            $Result = Set-NBDCIMRack -Id 1 -Name 'UpdatedRack' -Force
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/racks/1/'
        }
    }

    Context "Remove-NBDCIMRack" {
        It "Should remove a rack" {
            $Result = Remove-NBDCIMRack -Id 10 -Force
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/racks/10/'
        }
    }
}
