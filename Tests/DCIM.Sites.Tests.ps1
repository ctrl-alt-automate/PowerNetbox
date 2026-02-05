param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "DCIM Sites Tests" -Tag 'DCIM', 'Sites' {
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
            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 1 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/sites/'
            $Result.Body | Should -Match '"name":"NewSite"'
            $Result.Body | Should -Match '"slug":"newsite"'
        }
    }

    Context "Set-NBDCIMSite" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMSite" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = $Name }
            }
        }

        It "Should update a site" {
            $Result = Set-NBDCIMSite -Id 1 -Name 'UpdatedSite' -Force
            # Performance optimization: no longer fetches the object before updating
            Should -Invoke -CommandName 'Get-NBDCIMSite' -Times 0 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/sites/1/'
            $Result.Body | Should -Match '"name":"UpdatedSite"'
        }
    }

    Context "Remove-NBDCIMSite" {
        It "Should remove a site" {
            # Remove-NBDCIMSite uses SupportsShouldProcess, use -Confirm:$false instead of -Force
            $Result = Remove-NBDCIMSite -Id 10 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/sites/10/'
        }
    }
}
