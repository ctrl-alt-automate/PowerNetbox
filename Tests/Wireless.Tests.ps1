<#
.SYNOPSIS
    Unit tests for Wireless module functions.

.DESCRIPTION
    Tests for all Wireless endpoints: WirelessLAN, WirelessLANGroup, WirelessLink.
#>

param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "Wireless Module Tests" -Tag 'Wireless' {
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

    #region Wireless LAN Tests
    Context "Get-NBWirelessLAN" {
        It "Should request wireless LANs" {
            $Result = Get-NBWirelessLAN
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/'
        }

        It "Should request a wireless LAN by ID" {
            $Result = Get-NBWirelessLAN -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/5/'
        }

        It "Should request wireless LANs by SSID" {
            $Result = Get-NBWirelessLAN -SSID 'TestWiFi'
            $Result.Uri | Should -Match 'ssid=TestWiFi'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBWirelessLAN -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 15 } | Get-NBWirelessLAN
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/15/'
        }
    }

    Context "New-NBWirelessLAN" {
        It "Should create a wireless LAN" {
            $Result = New-NBWirelessLAN -SSID "TestWiFi" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.ssid | Should -Be 'TestWiFi'
        }

        It "Should create a wireless LAN with optional parameters" {
            $Result = New-NBWirelessLAN -SSID "CorpWiFi" -Description "Corporate wireless" -Status "active" -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.ssid | Should -Be 'CorpWiFi'
            $bodyObj.description | Should -Be 'Corporate wireless'
        }

        It "Should support -WhatIf" {
            $Result = New-NBWirelessLAN -SSID "WhatIfWiFi" -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBWirelessLAN" {
        It "Should update a wireless LAN" {
            $Result = Set-NBWirelessLAN -Id 1 -SSID 'UpdatedSSID' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.ssid | Should -Be 'UpdatedSSID'
        }

        It "Should update multiple fields" {
            $Result = Set-NBWirelessLAN -Id 1 -Description 'Updated description' -Status 'deprecated' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Updated description'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 10 } | Set-NBWirelessLAN -SSID 'PipedSSID' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/10/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBWirelessLAN -Id 1 -SSID 'WhatIfSSID' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBWirelessLAN" {
        It "Should delete a wireless LAN" {
            $Result = Remove-NBWirelessLAN -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/1/'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 25 } | Remove-NBWirelessLAN -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/25/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBWirelessLAN -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Wireless LAN Group Tests
    Context "Get-NBWirelessLANGroup" {
        It "Should request wireless LAN groups" {
            $Result = Get-NBWirelessLANGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lan-groups/'
        }

        It "Should request a wireless LAN group by ID" {
            $Result = Get-NBWirelessLANGroup -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lan-groups/5/'
        }

        It "Should request wireless LAN groups by name" {
            $Result = Get-NBWirelessLANGroup -Name 'Guest Networks'
            $Result.Uri | Should -Match 'name=Guest'
        }

        It "Should request wireless LAN groups by slug" {
            $Result = Get-NBWirelessLANGroup -Slug 'guest-networks'
            $Result.Uri | Should -Match 'slug=guest-networks'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBWirelessLANGroup -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBWirelessLANGroup" {
        It "Should create a wireless LAN group" {
            $Result = New-NBWirelessLANGroup -Name "Guest Networks" -Slug "guest-networks" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lan-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Guest Networks'
            $bodyObj.slug | Should -Be 'guest-networks'
        }

        It "Should create with optional description" {
            $Result = New-NBWirelessLANGroup -Name "IoT Devices" -Slug "iot-devices" -Description "IoT wireless networks" -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'IoT wireless networks'
        }

        It "Should support -WhatIf" {
            $Result = New-NBWirelessLANGroup -Name "WhatIf Group" -Slug "whatif-group" -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBWirelessLANGroup" {
        It "Should update a wireless LAN group" {
            $Result = Set-NBWirelessLANGroup -Id 1 -Name 'Updated Group' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lan-groups/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Updated Group'
        }

        It "Should update description" {
            $Result = Set-NBWirelessLANGroup -Id 2 -Description 'New description' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'New description'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBWirelessLANGroup -Id 1 -Name 'WhatIf' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBWirelessLANGroup" {
        It "Should delete a wireless LAN group" {
            $Result = Remove-NBWirelessLANGroup -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lan-groups/1/'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 30 } | Remove-NBWirelessLANGroup -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lan-groups/30/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBWirelessLANGroup -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Wireless Link Tests
    Context "Get-NBWirelessLink" {
        It "Should request wireless links" {
            $Result = Get-NBWirelessLink
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-links/'
        }

        It "Should request a wireless link by ID" {
            $Result = Get-NBWirelessLink -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-links/5/'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBWirelessLink -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBWirelessLink" {
        It "Should create a wireless link" {
            $Result = New-NBWirelessLink -Interface_A 1 -Interface_B 2 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-links/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.interface_a | Should -Be 1
            $bodyObj.interface_b | Should -Be 2
        }

        It "Should create with optional SSID" {
            $Result = New-NBWirelessLink -Interface_A 1 -Interface_B 2 -SSID "LinkSSID" -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.ssid | Should -Be 'LinkSSID'
        }

        It "Should support -WhatIf" {
            $Result = New-NBWirelessLink -Interface_A 1 -Interface_B 2 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBWirelessLink" {
        It "Should update a wireless link" {
            $Result = Set-NBWirelessLink -Id 1 -SSID 'UpdatedLinkSSID' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-links/1/'
        }

        It "Should update status" {
            $Result = Set-NBWirelessLink -Id 1 -Status 'connected' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.status | Should -Be 'connected'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBWirelessLink -Id 1 -SSID 'WhatIfSSID' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBWirelessLink" {
        It "Should delete a wireless link" {
            $Result = Remove-NBWirelessLink -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-links/1/'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 35 } | Remove-NBWirelessLink -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-links/35/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBWirelessLink -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Pagination Parameter Tests
    Context "Wireless Get- Functions Pagination Support" {
        It "Get-NBWirelessLAN should have -All parameter" {
            $cmd = Get-Command Get-NBWirelessLAN
            $cmd.Parameters.Keys | Should -Contain 'All'
            $cmd.Parameters['All'].ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It "Get-NBWirelessLAN should have -PageSize parameter" {
            $cmd = Get-Command Get-NBWirelessLAN
            $cmd.Parameters.Keys | Should -Contain 'PageSize'
            $cmd.Parameters['PageSize'].ParameterType.Name | Should -Be 'Int32'
        }

        It "Get-NBWirelessLANGroup should have -All parameter" {
            $cmd = Get-Command Get-NBWirelessLANGroup
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBWirelessLANGroup should have -PageSize parameter" {
            $cmd = Get-Command Get-NBWirelessLANGroup
            $cmd.Parameters.Keys | Should -Contain 'PageSize'
        }

        It "Get-NBWirelessLink should have -All parameter" {
            $cmd = Get-Command Get-NBWirelessLink
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBWirelessLink should have -PageSize parameter" {
            $cmd = Get-Command Get-NBWirelessLink
            $cmd.Parameters.Keys | Should -Contain 'PageSize'
        }
    }
    #endregion

    #region Omit Parameter Tests
    Context "Omit Parameter" {
        $omitTestCases = @(
            @{ Command = 'Get-NBWirelessLAN' }
            @{ Command = 'Get-NBWirelessLANGroup' }
            @{ Command = 'Get-NBWirelessLink' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion
}
