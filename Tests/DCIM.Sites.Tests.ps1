[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module NetboxPSv4 -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path $PSScriptRoot ".." "NetboxPSv4" "NetboxPSv4.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "DCIM Sites Tests" -Tag 'DCIM', 'Sites' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'NetboxPSv4' -MockWith { return $true }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'NetboxPSv4' -MockWith {
            return [ordered]@{
                'Method'      = $Method
                'Uri'         = $Uri
                'Headers'     = $Headers
                'Timeout'     = $Timeout
                'ContentType' = $ContentType
                'Body'        = $Body
            }
        }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'NetboxPSv4' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'NetboxPSv4' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'NetboxPSv4' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'NetboxPSv4' -MockWith { return @{} }

        InModuleScope -ModuleName 'NetboxPSv4' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Get-NBDCIMSite" {
        It "Should request sites" {
            $Result = Get-NBDCIMSite
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/'
        }

        It "Should request a site by name" {
            $Result = Get-NBDCIMSite -Name 'TestSite'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/?name=TestSite'
        }

        It "Should request a site by ID" {
            $Result = Get-NBDCIMSite -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/5/'
        }
    }

    Context "New-NBDCIMSite" {
        It "Should create a new site" {
            $Result = New-NBDCIMSite -Name "NewSite" -Slug "newsite"
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It' -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/'
            $Result.Body | Should -Match '"name":"NewSite"'
            $Result.Body | Should -Match '"slug":"newsite"'
        }
    }

    Context "Set-NBDCIMSite" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMSite" -ModuleName NetboxPSv4 -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = $Name }
            }
        }

        It "Should update a site" {
            $Result = Set-NBDCIMSite -Id 1 -Name 'UpdatedSite' -Force
            Should -Invoke -CommandName 'Get-NBDCIMSite' -Times 1 -Exactly -Scope 'It' -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/sites/1/'
            $Result.Body | Should -Match '"name":"UpdatedSite"'
        }
    }

    Context "Remove-NBDCIMSite" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMSite" -ModuleName NetboxPSv4 -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = $Name }
            }
        }

        It "Should remove a site" {
            # Remove-NBDCIMSite uses SupportsShouldProcess, use -Confirm:$false instead of -Force
            $Result = Remove-NBDCIMSite -Id 10 -Confirm:$false
            Should -Invoke -CommandName 'Get-NBDCIMSite' -Times 1 -Exactly -Scope 'It' -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/sites/10/'
        }
    }
}
