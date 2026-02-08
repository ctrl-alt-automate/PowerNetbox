<#
.SYNOPSIS
    Unit tests for DCIM Template functions and Platform functions.

.DESCRIPTION
    Tests for DCIM Template endpoints:
    ConsolePortTemplates, ConsoleServerPortTemplates, DeviceBayTemplates,
    FrontPortTemplates, InterfaceTemplates, InventoryItemTemplates,
    ModuleBayTemplates, PowerOutletTemplates, PowerPortTemplates, RearPortTemplates,
    and Platform functions (New/Set/Remove).
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

Describe "DCIM Template Functions" -Tag 'Build', 'DCIM' {
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

    #region ConsolePortTemplates
    Context "Get-NBDCIMConsolePortTemplate" {
        It "Should request console port templates" {
            $Result = Get-NBDCIMConsolePortTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-port-templates/'
        }

        It "Should request a console port template by ID" {
            $Result = Get-NBDCIMConsolePortTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/console-port-templates/10/'
        }
    }

    Context "New-NBDCIMConsolePortTemplate" {
        It "Should create a console port template" {
            $Result = New-NBDCIMConsolePortTemplate -Device_Type 1 -Name 'con0' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-port-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'con0'
        }
    }

    Context "Set-NBDCIMConsolePortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsolePortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'con0' }
            }
        }

        It "Should update a console port template" {
            $Result = Set-NBDCIMConsolePortTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/console-port-templates/1/'
        }
    }

    Context "Remove-NBDCIMConsolePortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsolePortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'con0' }
            }
        }

        It "Should remove a console port template" {
            $Result = Remove-NBDCIMConsolePortTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/console-port-templates/2/'
        }
    }
    #endregion

    #region ConsoleServerPortTemplates
    Context "Get-NBDCIMConsoleServerPortTemplate" {
        It "Should request console server port templates" {
            $Result = Get-NBDCIMConsoleServerPortTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-server-port-templates/'
        }

        It "Should request a console server port template by ID" {
            $Result = Get-NBDCIMConsoleServerPortTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/console-server-port-templates/10/'
        }
    }

    Context "New-NBDCIMConsoleServerPortTemplate" {
        It "Should create a console server port template" {
            $Result = New-NBDCIMConsoleServerPortTemplate -Device_Type 1 -Name 'port1' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-server-port-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'port1'
        }
    }

    Context "Set-NBDCIMConsoleServerPortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsoleServerPortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'port1' }
            }
        }

        It "Should update a console server port template" {
            $Result = Set-NBDCIMConsoleServerPortTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/console-server-port-templates/1/'
        }
    }

    Context "Remove-NBDCIMConsoleServerPortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsoleServerPortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'port1' }
            }
        }

        It "Should remove a console server port template" {
            $Result = Remove-NBDCIMConsoleServerPortTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/console-server-port-templates/2/'
        }
    }
    #endregion

    #region DeviceBayTemplates
    Context "Get-NBDCIMDeviceBayTemplate" {
        It "Should request device bay templates" {
            $Result = Get-NBDCIMDeviceBayTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-bay-templates/'
        }

        It "Should request a device bay template by ID" {
            $Result = Get-NBDCIMDeviceBayTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/device-bay-templates/10/'
        }
    }

    Context "New-NBDCIMDeviceBayTemplate" {
        It "Should create a device bay template" {
            $Result = New-NBDCIMDeviceBayTemplate -Device_Type 1 -Name 'Bay1' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-bay-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'Bay1'
        }
    }

    Context "Set-NBDCIMDeviceBayTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDeviceBayTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Bay1' }
            }
        }

        It "Should update a device bay template" {
            $Result = Set-NBDCIMDeviceBayTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/device-bay-templates/1/'
        }
    }

    Context "Remove-NBDCIMDeviceBayTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDeviceBayTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Bay1' }
            }
        }

        It "Should remove a device bay template" {
            $Result = Remove-NBDCIMDeviceBayTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/device-bay-templates/2/'
        }
    }
    #endregion

    #region FrontPortTemplates
    Context "Get-NBDCIMFrontPortTemplate" {
        It "Should request front port templates" {
            $Result = Get-NBDCIMFrontPortTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/front-port-templates/'
        }

        It "Should request a front port template by ID" {
            $Result = Get-NBDCIMFrontPortTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/front-port-templates/10/'
        }
    }

    Context "New-NBDCIMFrontPortTemplate" {
        It "Should create a front port template" {
            $Result = New-NBDCIMFrontPortTemplate -Device_Type 1 -Name 'FP1' -Type '8p8c' -Rear_Port 1 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/front-port-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'FP1'
            $bodyObj.type | Should -Be '8p8c'
            $bodyObj.rear_port | Should -Be 1
        }
    }

    Context "Set-NBDCIMFrontPortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMFrontPortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'FP1' }
            }
        }

        It "Should update a front port template" {
            $Result = Set-NBDCIMFrontPortTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/front-port-templates/1/'
        }
    }

    Context "Remove-NBDCIMFrontPortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMFrontPortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'FP1' }
            }
        }

        It "Should remove a front port template" {
            $Result = Remove-NBDCIMFrontPortTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/front-port-templates/2/'
        }
    }
    #endregion

    #region InterfaceTemplates
    Context "Get-NBDCIMInterfaceTemplate" {
        It "Should request interface templates" {
            $Result = Get-NBDCIMInterfaceTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interface-templates/'
        }

        It "Should request an interface template by ID" {
            $Result = Get-NBDCIMInterfaceTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/interface-templates/10/'
        }
    }

    Context "New-NBDCIMInterfaceTemplate" {
        It "Should create an interface template" {
            $Result = New-NBDCIMInterfaceTemplate -Device_Type 1 -Name 'eth0' -Type '1000base-t' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interface-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'eth0'
            $bodyObj.type | Should -Be '1000base-t'
        }
    }

    Context "Set-NBDCIMInterfaceTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInterfaceTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'eth0' }
            }
        }

        It "Should update an interface template" {
            $Result = Set-NBDCIMInterfaceTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/interface-templates/1/'
        }
    }

    Context "Remove-NBDCIMInterfaceTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInterfaceTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'eth0' }
            }
        }

        It "Should remove an interface template" {
            $Result = Remove-NBDCIMInterfaceTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/interface-templates/2/'
        }
    }
    #endregion

    #region InventoryItemTemplates
    Context "Get-NBDCIMInventoryItemTemplate" {
        It "Should request inventory item templates" {
            $Result = Get-NBDCIMInventoryItemTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-item-templates/'
        }

        It "Should request an inventory item template by ID" {
            $Result = Get-NBDCIMInventoryItemTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/inventory-item-templates/10/'
        }
    }

    Context "New-NBDCIMInventoryItemTemplate" {
        It "Should create an inventory item template" {
            $Result = New-NBDCIMInventoryItemTemplate -Device_Type 1 -Name 'SFP-1' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-item-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'SFP-1'
        }
    }

    Context "Set-NBDCIMInventoryItemTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItemTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'SFP-1' }
            }
        }

        It "Should update an inventory item template" {
            $Result = Set-NBDCIMInventoryItemTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/inventory-item-templates/1/'
        }
    }

    Context "Remove-NBDCIMInventoryItemTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItemTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'SFP-1' }
            }
        }

        It "Should remove an inventory item template" {
            $Result = Remove-NBDCIMInventoryItemTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/inventory-item-templates/2/'
        }
    }
    #endregion

    #region ModuleBayTemplates
    Context "Get-NBDCIMModuleBayTemplate" {
        It "Should request module bay templates" {
            $Result = Get-NBDCIMModuleBayTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-templates/'
        }

        It "Should request a module bay template by ID" {
            $Result = Get-NBDCIMModuleBayTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/module-bay-templates/10/'
        }
    }

    Context "New-NBDCIMModuleBayTemplate" {
        It "Should create a module bay template" {
            $Result = New-NBDCIMModuleBayTemplate -Device_Type 1 -Name 'ModBay1' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'ModBay1'
        }
    }

    Context "Set-NBDCIMModuleBayTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleBayTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'ModBay1' }
            }
        }

        It "Should update a module bay template" {
            $Result = Set-NBDCIMModuleBayTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/module-bay-templates/1/'
        }
    }

    Context "Remove-NBDCIMModuleBayTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleBayTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'ModBay1' }
            }
        }

        It "Should remove a module bay template" {
            $Result = Remove-NBDCIMModuleBayTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/module-bay-templates/2/'
        }
    }
    #endregion

    #region PowerOutletTemplates
    Context "Get-NBDCIMPowerOutletTemplate" {
        It "Should request power outlet templates" {
            $Result = Get-NBDCIMPowerOutletTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-outlet-templates/'
        }

        It "Should request a power outlet template by ID" {
            $Result = Get-NBDCIMPowerOutletTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/power-outlet-templates/10/'
        }
    }

    Context "New-NBDCIMPowerOutletTemplate" {
        It "Should create a power outlet template" {
            $Result = New-NBDCIMPowerOutletTemplate -Device_Type 1 -Name 'Outlet1' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-outlet-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'Outlet1'
        }
    }

    Context "Set-NBDCIMPowerOutletTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerOutletTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Outlet1' }
            }
        }

        It "Should update a power outlet template" {
            $Result = Set-NBDCIMPowerOutletTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/power-outlet-templates/1/'
        }
    }

    Context "Remove-NBDCIMPowerOutletTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerOutletTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Outlet1' }
            }
        }

        It "Should remove a power outlet template" {
            $Result = Remove-NBDCIMPowerOutletTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/power-outlet-templates/2/'
        }
    }
    #endregion

    #region PowerPortTemplates
    Context "Get-NBDCIMPowerPortTemplate" {
        It "Should request power port templates" {
            $Result = Get-NBDCIMPowerPortTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-port-templates/'
        }

        It "Should request a power port template by ID" {
            $Result = Get-NBDCIMPowerPortTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/power-port-templates/10/'
        }
    }

    Context "New-NBDCIMPowerPortTemplate" {
        It "Should create a power port template" {
            $Result = New-NBDCIMPowerPortTemplate -Device_Type 1 -Name 'PSU1' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-port-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'PSU1'
        }
    }

    Context "Set-NBDCIMPowerPortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'PSU1' }
            }
        }

        It "Should update a power port template" {
            $Result = Set-NBDCIMPowerPortTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/power-port-templates/1/'
        }
    }

    Context "Remove-NBDCIMPowerPortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'PSU1' }
            }
        }

        It "Should remove a power port template" {
            $Result = Remove-NBDCIMPowerPortTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/power-port-templates/2/'
        }
    }
    #endregion

    #region RearPortTemplates
    Context "Get-NBDCIMRearPortTemplate" {
        It "Should request rear port templates" {
            $Result = Get-NBDCIMRearPortTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rear-port-templates/'
        }

        It "Should request a rear port template by ID" {
            $Result = Get-NBDCIMRearPortTemplate -Id 10
            $Result.Uri | Should -Match '/api/dcim/rear-port-templates/10/'
        }
    }

    Context "New-NBDCIMRearPortTemplate" {
        It "Should create a rear port template" {
            $Result = New-NBDCIMRearPortTemplate -Device_Type 1 -Name 'RP1' -Type '8p8c' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rear-port-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'RP1'
            $bodyObj.type | Should -Be '8p8c'
        }
    }

    Context "Set-NBDCIMRearPortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRearPortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'RP1' }
            }
        }

        It "Should update a rear port template" {
            $Result = Set-NBDCIMRearPortTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/rear-port-templates/1/'
        }
    }

    Context "Remove-NBDCIMRearPortTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRearPortTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'RP1' }
            }
        }

        It "Should remove a rear port template" {
            $Result = Remove-NBDCIMRearPortTemplate -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/rear-port-templates/2/'
        }
    }
    #endregion

    #region Platforms (New/Set/Remove)
    Context "New-NBDCIMPlatform" {
        It "Should create a platform" {
            $Result = New-NBDCIMPlatform -Name 'IOS-XE' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/platforms/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'IOS-XE'
        }

        It "Should create a platform with slug and manufacturer" {
            $Result = New-NBDCIMPlatform -Name 'NX-OS' -Slug 'nx-os' -Manufacturer 1 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'NX-OS'
            $bodyObj.slug | Should -Be 'nx-os'
            $bodyObj.manufacturer | Should -Be 1
        }
    }

    Context "Set-NBDCIMPlatform" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPlatform" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'IOS-XE' }
            }
        }

        It "Should update a platform" {
            $Result = Set-NBDCIMPlatform -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/platforms/1/'
        }

        It "Should update a platform name" {
            $Result = Set-NBDCIMPlatform -Id 1 -Name 'IOS-XE-New' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'IOS-XE-New'
        }
    }

    Context "Remove-NBDCIMPlatform" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPlatform" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'IOS-XE' }
            }
        }

        It "Should remove a platform" {
            $Result = Remove-NBDCIMPlatform -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/platforms/2/'
        }
    }
    #endregion

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBDCIMConsolePortTemplate'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMConsoleServerPortTemplate'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMDeviceBayTemplate'; Parameters = @{ Device_Type = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMFrontPortTemplate'; Parameters = @{ Name = 'whatif-test'; Type = 'whatif-test'; Rear_Port = 1 } }
            @{ Command = 'New-NBDCIMInterfaceTemplate'; Parameters = @{ Name = 'whatif-test'; Type = 'whatif-test' } }
            @{ Command = 'New-NBDCIMInventoryItemTemplate'; Parameters = @{ Device_Type = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMModuleBayTemplate'; Parameters = @{ Device_Type = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMPowerOutletTemplate'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMPowerPortTemplate'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMRearPortTemplate'; Parameters = @{ Name = 'whatif-test'; Type = 'whatif-test' } }
            @{ Command = 'Set-NBDCIMConsolePortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMConsoleServerPortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMDeviceBayTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMFrontPortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMInterfaceTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMInventoryItemTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMModuleBayTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMPowerOutletTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMPowerPortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMRearPortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMConsolePortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMConsoleServerPortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMDeviceBayTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMFrontPortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMInterfaceTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMInventoryItemTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMModuleBayTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMPowerOutletTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMPowerPortTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMRearPortTemplate'; Parameters = @{ Id = 1 } }
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
