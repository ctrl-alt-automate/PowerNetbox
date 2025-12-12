<#
.SYNOPSIS
    Unit tests for additional DCIM module functions.

.DESCRIPTION
    Tests for DCIM endpoints not covered in other DCIM test files:
    Cables, Locations, Regions, SiteGroups, Manufacturers, Racks (extended),
    RackTypes, RackRoles, RackReservations, ConsolePorts, ConsoleServerPorts,
    PowerPorts, PowerOutlets, PowerPanels, PowerFeeds, DeviceBays, Modules,
    ModuleTypes, ModuleBays, ModuleTypeProfiles, InventoryItems, InventoryItemRoles,
    FrontPorts, RearPorts, InterfaceTemplates, MACAddresses, VirtualChassis, VirtualDeviceContexts
#>

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

Describe "DCIM Additional Tests" -Tag 'DCIM' {
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

    #region Cables
    Context "Get-NBDCIMCable" {
        It "Should request cables" {
            $Result = Get-NBDCIMCable
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cables/'
        }

        It "Should request a cable by ID" {
            $Result = Get-NBDCIMCable -Id 5
            $Result.Uri | Should -Match '/api/dcim/cables/5/'
        }
    }

    Context "New-NBDCIMCable" {
        It "Should create a cable" {
            $Result = New-NBDCIMCable -A_Terminations_Type 'dcim.interface' -A_Terminations 1 -B_Terminations_Type 'dcim.interface' -B_Terminations 2
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cables/'
        }
    }

    Context "Set-NBDCIMCable" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMCable" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should update a cable" {
            $Result = Set-NBDCIMCable -Id 1 -Label 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/cables/1/'
        }
    }

    Context "Remove-NBDCIMCable" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMCable" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a cable" {
            $Result = Remove-NBDCIMCable -Id 3 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/cables/3/'
        }
    }
    #endregion

    #region Locations
    Context "Get-NBDCIMLocation" {
        It "Should request locations" {
            $Result = Get-NBDCIMLocation
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/locations/'
        }

        It "Should request a location by ID" {
            $Result = Get-NBDCIMLocation -Id 5
            $Result.Uri | Should -Match '/api/dcim/locations/5/'
        }

        It "Should request a location by name" {
            $Result = Get-NBDCIMLocation -Name 'Floor1'
            $Result.Uri | Should -Match 'name=Floor1'
        }
    }

    Context "New-NBDCIMLocation" {
        It "Should create a location" {
            $Result = New-NBDCIMLocation -Name 'TestLoc' -Slug 'test-loc' -Site 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/locations/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestLoc'
            $bodyObj.slug | Should -Be 'test-loc'
            $bodyObj.site | Should -Be 1
        }
    }

    Context "Set-NBDCIMLocation" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMLocation" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestLoc' }
            }
        }

        It "Should update a location" {
            $Result = Set-NBDCIMLocation -Id 1 -Name 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/locations/1/'
        }
    }

    Context "Remove-NBDCIMLocation" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMLocation" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestLoc' }
            }
        }

        It "Should remove a location" {
            $Result = Remove-NBDCIMLocation -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/locations/2/'
        }
    }
    #endregion

    #region Regions
    Context "Get-NBDCIMRegion" {
        It "Should request regions" {
            $Result = Get-NBDCIMRegion
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/regions/'
        }

        It "Should request a region by ID" {
            $Result = Get-NBDCIMRegion -Id 3
            $Result.Uri | Should -Match '/api/dcim/regions/3/'
        }
    }

    Context "New-NBDCIMRegion" {
        It "Should create a region" {
            $Result = New-NBDCIMRegion -Name 'Europe' -Slug 'europe'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/regions/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Europe'
            $bodyObj.slug | Should -Be 'europe'
        }
    }

    Context "Set-NBDCIMRegion" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRegion" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRegion' }
            }
        }

        It "Should update a region" {
            $Result = Set-NBDCIMRegion -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/regions/1/'
        }
    }

    Context "Remove-NBDCIMRegion" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRegion" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRegion' }
            }
        }

        It "Should remove a region" {
            $Result = Remove-NBDCIMRegion -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/regions/2/'
        }
    }
    #endregion

    #region SiteGroups
    Context "Get-NBDCIMSiteGroup" {
        It "Should request site groups" {
            $Result = Get-NBDCIMSiteGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/site-groups/'
        }

        It "Should request a site group by ID" {
            $Result = Get-NBDCIMSiteGroup -Id 4
            $Result.Uri | Should -Match '/api/dcim/site-groups/4/'
        }
    }

    Context "New-NBDCIMSiteGroup" {
        It "Should create a site group" {
            $Result = New-NBDCIMSiteGroup -Name 'DataCenters' -Slug 'datacenters'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/site-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'DataCenters'
        }
    }

    Context "Set-NBDCIMSiteGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMSiteGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should update a site group" {
            $Result = Set-NBDCIMSiteGroup -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/site-groups/1/'
        }
    }

    Context "Remove-NBDCIMSiteGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMSiteGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should remove a site group" {
            $Result = Remove-NBDCIMSiteGroup -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/site-groups/2/'
        }
    }
    #endregion

    #region Manufacturers
    Context "Get-NBDCIMManufacturer" {
        It "Should request manufacturers" {
            $Result = Get-NBDCIMManufacturer
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/manufacturers/'
        }

        It "Should request a manufacturer by ID" {
            $Result = Get-NBDCIMManufacturer -Id 5
            $Result.Uri | Should -Match '/api/dcim/manufacturers/5/'
        }

        It "Should request a manufacturer by name" {
            $Result = Get-NBDCIMManufacturer -Name 'Cisco'
            $Result.Uri | Should -Match 'name=Cisco'
        }
    }

    Context "New-NBDCIMManufacturer" {
        It "Should create a manufacturer" {
            $Result = New-NBDCIMManufacturer -Name 'Juniper' -Slug 'juniper'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/manufacturers/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Juniper'
            $bodyObj.slug | Should -Be 'juniper'
        }
    }

    Context "Set-NBDCIMManufacturer" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMManufacturer" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestMfr' }
            }
        }

        It "Should update a manufacturer" {
            $Result = Set-NBDCIMManufacturer -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/manufacturers/1/'
        }
    }

    Context "Remove-NBDCIMManufacturer" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMManufacturer" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestMfr' }
            }
        }

        It "Should remove a manufacturer" {
            $Result = Remove-NBDCIMManufacturer -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/manufacturers/2/'
        }
    }
    #endregion

    #region RackTypes
    Context "Get-NBDCIMRackType" {
        It "Should request rack types" {
            $Result = Get-NBDCIMRackType
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-types/'
        }

        It "Should request a rack type by ID" {
            $Result = Get-NBDCIMRackType -Id 3
            $Result.Uri | Should -Match '/api/dcim/rack-types/3/'
        }
    }

    Context "New-NBDCIMRackType" {
        It "Should create a rack type" {
            $Result = New-NBDCIMRackType -Manufacturer 1 -Model 'Standard42U' -Form_Factor '2-post-frame'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-types/'
        }
    }

    Context "Set-NBDCIMRackType" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Model' = 'TestType' }
            }
        }

        It "Should update a rack type" {
            $Result = Set-NBDCIMRackType -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/rack-types/1/'
        }
    }

    Context "Remove-NBDCIMRackType" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Model' = 'TestType' }
            }
        }

        It "Should remove a rack type" {
            $Result = Remove-NBDCIMRackType -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/rack-types/2/'
        }
    }
    #endregion

    #region RackRoles
    Context "Get-NBDCIMRackRole" {
        It "Should request rack roles" {
            $Result = Get-NBDCIMRackRole
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-roles/'
        }

        It "Should request a rack role by ID" {
            $Result = Get-NBDCIMRackRole -Id 2
            $Result.Uri | Should -Match '/api/dcim/rack-roles/2/'
        }
    }

    Context "New-NBDCIMRackRole" {
        It "Should create a rack role" {
            $Result = New-NBDCIMRackRole -Name 'Network' -Slug 'network'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-roles/'
        }
    }

    Context "Set-NBDCIMRackRole" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRole' }
            }
        }

        It "Should update a rack role" {
            $Result = Set-NBDCIMRackRole -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/rack-roles/1/'
        }
    }

    Context "Remove-NBDCIMRackRole" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRole' }
            }
        }

        It "Should remove a rack role" {
            $Result = Remove-NBDCIMRackRole -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/rack-roles/2/'
        }
    }
    #endregion

    #region RackReservations
    Context "Get-NBDCIMRackReservation" {
        It "Should request rack reservations" {
            $Result = Get-NBDCIMRackReservation
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-reservations/'
        }

        It "Should request a rack reservation by ID" {
            $Result = Get-NBDCIMRackReservation -Id 5
            $Result.Uri | Should -Match '/api/dcim/rack-reservations/5/'
        }
    }

    Context "New-NBDCIMRackReservation" {
        It "Should create a rack reservation" {
            $Result = New-NBDCIMRackReservation -Rack 1 -Units @(1,2,3) -User 1 -Description 'Test'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-reservations/'
        }
    }

    Context "Set-NBDCIMRackReservation" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackReservation" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should update a rack reservation" {
            $Result = Set-NBDCIMRackReservation -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/rack-reservations/1/'
        }
    }

    Context "Remove-NBDCIMRackReservation" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackReservation" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a rack reservation" {
            $Result = Remove-NBDCIMRackReservation -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/rack-reservations/2/'
        }
    }
    #endregion

    #region ConsolePorts
    Context "Get-NBDCIMConsolePort" {
        It "Should request console ports" {
            $Result = Get-NBDCIMConsolePort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-ports/'
        }

        It "Should request a console port by ID" {
            $Result = Get-NBDCIMConsolePort -Id 5
            $Result.Uri | Should -Match '/api/dcim/console-ports/5/'
        }
    }

    Context "New-NBDCIMConsolePort" {
        It "Should create a console port" {
            $Result = New-NBDCIMConsolePort -Device 1 -Name 'con0'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-ports/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device | Should -Be 1
            $bodyObj.name | Should -Be 'con0'
        }
    }

    Context "Set-NBDCIMConsolePort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsolePort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'con0' }
            }
        }

        It "Should update a console port" {
            $Result = Set-NBDCIMConsolePort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/console-ports/1/'
        }
    }

    Context "Remove-NBDCIMConsolePort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsolePort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'con0' }
            }
        }

        It "Should remove a console port" {
            $Result = Remove-NBDCIMConsolePort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/console-ports/2/'
        }
    }
    #endregion

    #region ConsoleServerPorts
    Context "Get-NBDCIMConsoleServerPort" {
        It "Should request console server ports" {
            $Result = Get-NBDCIMConsoleServerPort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-server-ports/'
        }

        It "Should request a console server port by ID" {
            $Result = Get-NBDCIMConsoleServerPort -Id 5
            $Result.Uri | Should -Match '/api/dcim/console-server-ports/5/'
        }
    }

    Context "New-NBDCIMConsoleServerPort" {
        It "Should create a console server port" {
            $Result = New-NBDCIMConsoleServerPort -Device 1 -Name 'port1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-server-ports/'
        }
    }

    Context "Set-NBDCIMConsoleServerPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsoleServerPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'port1' }
            }
        }

        It "Should update a console server port" {
            $Result = Set-NBDCIMConsoleServerPort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/console-server-ports/1/'
        }
    }

    Context "Remove-NBDCIMConsoleServerPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsoleServerPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'port1' }
            }
        }

        It "Should remove a console server port" {
            $Result = Remove-NBDCIMConsoleServerPort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/console-server-ports/2/'
        }
    }
    #endregion

    #region PowerPorts
    Context "Get-NBDCIMPowerPort" {
        It "Should request power ports" {
            $Result = Get-NBDCIMPowerPort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-ports/'
        }

        It "Should request a power port by ID" {
            $Result = Get-NBDCIMPowerPort -Id 5
            $Result.Uri | Should -Match '/api/dcim/power-ports/5/'
        }
    }

    Context "New-NBDCIMPowerPort" {
        It "Should create a power port" {
            $Result = New-NBDCIMPowerPort -Device 1 -Name 'PSU1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-ports/'
        }
    }

    Context "Set-NBDCIMPowerPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'PSU1' }
            }
        }

        It "Should update a power port" {
            $Result = Set-NBDCIMPowerPort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/power-ports/1/'
        }
    }

    Context "Remove-NBDCIMPowerPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'PSU1' }
            }
        }

        It "Should remove a power port" {
            $Result = Remove-NBDCIMPowerPort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/power-ports/2/'
        }
    }
    #endregion

    #region PowerOutlets
    Context "Get-NBDCIMPowerOutlet" {
        It "Should request power outlets" {
            $Result = Get-NBDCIMPowerOutlet
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-outlets/'
        }

        It "Should request a power outlet by ID" {
            $Result = Get-NBDCIMPowerOutlet -Id 5
            $Result.Uri | Should -Match '/api/dcim/power-outlets/5/'
        }
    }

    Context "New-NBDCIMPowerOutlet" {
        It "Should create a power outlet" {
            $Result = New-NBDCIMPowerOutlet -Device 1 -Name 'Outlet1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-outlets/'
        }
    }

    Context "Set-NBDCIMPowerOutlet" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerOutlet" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Outlet1' }
            }
        }

        It "Should update a power outlet" {
            $Result = Set-NBDCIMPowerOutlet -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/power-outlets/1/'
        }
    }

    Context "Remove-NBDCIMPowerOutlet" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerOutlet" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Outlet1' }
            }
        }

        It "Should remove a power outlet" {
            $Result = Remove-NBDCIMPowerOutlet -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/power-outlets/2/'
        }
    }
    #endregion

    #region PowerPanels
    Context "Get-NBDCIMPowerPanel" {
        It "Should request power panels" {
            $Result = Get-NBDCIMPowerPanel
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-panels/'
        }

        It "Should request a power panel by ID" {
            $Result = Get-NBDCIMPowerPanel -Id 5
            $Result.Uri | Should -Match '/api/dcim/power-panels/5/'
        }
    }

    Context "New-NBDCIMPowerPanel" {
        It "Should create a power panel" {
            $Result = New-NBDCIMPowerPanel -Site 1 -Name 'Panel-A'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-panels/'
        }
    }

    Context "Set-NBDCIMPowerPanel" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPanel" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Panel-A' }
            }
        }

        It "Should update a power panel" {
            $Result = Set-NBDCIMPowerPanel -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/power-panels/1/'
        }
    }

    Context "Remove-NBDCIMPowerPanel" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPanel" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Panel-A' }
            }
        }

        It "Should remove a power panel" {
            $Result = Remove-NBDCIMPowerPanel -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/power-panels/2/'
        }
    }
    #endregion

    #region PowerFeeds
    Context "Get-NBDCIMPowerFeed" {
        It "Should request power feeds" {
            $Result = Get-NBDCIMPowerFeed
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-feeds/'
        }

        It "Should request a power feed by ID" {
            $Result = Get-NBDCIMPowerFeed -Id 5
            $Result.Uri | Should -Match '/api/dcim/power-feeds/5/'
        }
    }

    Context "New-NBDCIMPowerFeed" {
        It "Should create a power feed" {
            $Result = New-NBDCIMPowerFeed -Power_Panel 1 -Name 'Feed-A'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-feeds/'
        }
    }

    Context "Set-NBDCIMPowerFeed" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerFeed" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Feed-A' }
            }
        }

        It "Should update a power feed" {
            $Result = Set-NBDCIMPowerFeed -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/power-feeds/1/'
        }
    }

    Context "Remove-NBDCIMPowerFeed" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerFeed" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Feed-A' }
            }
        }

        It "Should remove a power feed" {
            $Result = Remove-NBDCIMPowerFeed -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/power-feeds/2/'
        }
    }
    #endregion

    #region DeviceBays
    Context "Get-NBDCIMDeviceBay" {
        It "Should request device bays" {
            $Result = Get-NBDCIMDeviceBay
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-bays/'
        }

        It "Should request a device bay by ID" {
            $Result = Get-NBDCIMDeviceBay -Id 5
            $Result.Uri | Should -Match '/api/dcim/device-bays/5/'
        }
    }

    Context "New-NBDCIMDeviceBay" {
        It "Should create a device bay" {
            $Result = New-NBDCIMDeviceBay -Device 1 -Name 'Bay1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-bays/'
        }
    }

    Context "Set-NBDCIMDeviceBay" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDeviceBay" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Bay1' }
            }
        }

        It "Should update a device bay" {
            $Result = Set-NBDCIMDeviceBay -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/device-bays/1/'
        }
    }

    Context "Remove-NBDCIMDeviceBay" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDeviceBay" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Bay1' }
            }
        }

        It "Should remove a device bay" {
            $Result = Remove-NBDCIMDeviceBay -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/device-bays/2/'
        }
    }
    #endregion

    #region Modules
    Context "Get-NBDCIMModule" {
        It "Should request modules" {
            $Result = Get-NBDCIMModule
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/modules/'
        }

        It "Should request a module by ID" {
            $Result = Get-NBDCIMModule -Id 5
            $Result.Uri | Should -Match '/api/dcim/modules/5/'
        }
    }

    Context "New-NBDCIMModule" {
        It "Should create a module" {
            $Result = New-NBDCIMModule -Device 1 -Module_Bay 1 -Module_Type 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/modules/'
        }
    }

    Context "Set-NBDCIMModule" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModule" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should update a module" {
            $Result = Set-NBDCIMModule -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/modules/1/'
        }
    }

    Context "Remove-NBDCIMModule" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModule" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a module" {
            $Result = Remove-NBDCIMModule -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/modules/2/'
        }
    }
    #endregion

    #region ModuleTypes
    Context "Get-NBDCIMModuleType" {
        It "Should request module types" {
            $Result = Get-NBDCIMModuleType
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-types/'
        }

        It "Should request a module type by ID" {
            $Result = Get-NBDCIMModuleType -Id 5
            $Result.Uri | Should -Match '/api/dcim/module-types/5/'
        }
    }

    Context "New-NBDCIMModuleType" {
        It "Should create a module type" {
            $Result = New-NBDCIMModuleType -Manufacturer 1 -Model 'SFP-Module'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-types/'
        }
    }

    Context "Set-NBDCIMModuleType" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Model' = 'SFP' }
            }
        }

        It "Should update a module type" {
            $Result = Set-NBDCIMModuleType -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/module-types/1/'
        }
    }

    Context "Remove-NBDCIMModuleType" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Model' = 'SFP' }
            }
        }

        It "Should remove a module type" {
            $Result = Remove-NBDCIMModuleType -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/module-types/2/'
        }
    }
    #endregion

    #region ModuleBays
    Context "Get-NBDCIMModuleBay" {
        It "Should request module bays" {
            $Result = Get-NBDCIMModuleBay
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bays/'
        }

        It "Should request a module bay by ID" {
            $Result = Get-NBDCIMModuleBay -Id 5
            $Result.Uri | Should -Match '/api/dcim/module-bays/5/'
        }
    }

    Context "New-NBDCIMModuleBay" {
        It "Should create a module bay" {
            $Result = New-NBDCIMModuleBay -Device 1 -Name 'ModBay1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bays/'
        }
    }

    Context "Set-NBDCIMModuleBay" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleBay" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'ModBay1' }
            }
        }

        It "Should update a module bay" {
            $Result = Set-NBDCIMModuleBay -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/module-bays/1/'
        }
    }

    Context "Remove-NBDCIMModuleBay" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleBay" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'ModBay1' }
            }
        }

        It "Should remove a module bay" {
            $Result = Remove-NBDCIMModuleBay -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/module-bays/2/'
        }
    }
    #endregion

    #region ModuleTypeProfiles
    Context "Get-NBDCIMModuleTypeProfile" {
        It "Should request module type profiles" {
            $Result = Get-NBDCIMModuleTypeProfile
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-type-profiles/'
        }

        It "Should request a module type profile by ID" {
            $Result = Get-NBDCIMModuleTypeProfile -Id 5
            $Result.Uri | Should -Match '/api/dcim/module-type-profiles/5/'
        }
    }

    Context "New-NBDCIMModuleTypeProfile" {
        It "Should create a module type profile" {
            $Result = New-NBDCIMModuleTypeProfile -Name 'Profile1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-type-profiles/'
        }
    }

    Context "Set-NBDCIMModuleTypeProfile" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleTypeProfile" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Profile1' }
            }
        }

        It "Should update a module type profile" {
            $Result = Set-NBDCIMModuleTypeProfile -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/module-type-profiles/1/'
        }
    }

    Context "Remove-NBDCIMModuleTypeProfile" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleTypeProfile" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Profile1' }
            }
        }

        It "Should remove a module type profile" {
            $Result = Remove-NBDCIMModuleTypeProfile -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/module-type-profiles/2/'
        }
    }
    #endregion

    #region InventoryItems
    Context "Get-NBDCIMInventoryItem" {
        It "Should request inventory items" {
            $Result = Get-NBDCIMInventoryItem
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-items/'
        }

        It "Should request an inventory item by ID" {
            $Result = Get-NBDCIMInventoryItem -Id 5
            $Result.Uri | Should -Match '/api/dcim/inventory-items/5/'
        }
    }

    Context "New-NBDCIMInventoryItem" {
        It "Should create an inventory item" {
            $Result = New-NBDCIMInventoryItem -Device 1 -Name 'SFP-1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-items/'
        }
    }

    Context "Set-NBDCIMInventoryItem" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItem" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'SFP-1' }
            }
        }

        It "Should update an inventory item" {
            $Result = Set-NBDCIMInventoryItem -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/inventory-items/1/'
        }
    }

    Context "Remove-NBDCIMInventoryItem" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItem" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'SFP-1' }
            }
        }

        It "Should remove an inventory item" {
            $Result = Remove-NBDCIMInventoryItem -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/inventory-items/2/'
        }
    }
    #endregion

    #region InventoryItemRoles
    Context "Get-NBDCIMInventoryItemRole" {
        It "Should request inventory item roles" {
            $Result = Get-NBDCIMInventoryItemRole
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-item-roles/'
        }

        It "Should request an inventory item role by ID" {
            $Result = Get-NBDCIMInventoryItemRole -Id 5
            $Result.Uri | Should -Match '/api/dcim/inventory-item-roles/5/'
        }
    }

    Context "New-NBDCIMInventoryItemRole" {
        It "Should create an inventory item role" {
            $Result = New-NBDCIMInventoryItemRole -Name 'Optic' -Slug 'optic'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-item-roles/'
        }
    }

    Context "Set-NBDCIMInventoryItemRole" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItemRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Optic' }
            }
        }

        It "Should update an inventory item role" {
            $Result = Set-NBDCIMInventoryItemRole -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/inventory-item-roles/1/'
        }
    }

    Context "Remove-NBDCIMInventoryItemRole" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItemRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Optic' }
            }
        }

        It "Should remove an inventory item role" {
            $Result = Remove-NBDCIMInventoryItemRole -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/inventory-item-roles/2/'
        }
    }
    #endregion

    #region FrontPorts
    Context "Get-NBDCIMFrontPort" {
        It "Should request front ports" {
            $Result = Get-NBDCIMFrontPort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/front-ports/'
        }

        It "Should request a front port by ID" {
            $Result = Get-NBDCIMFrontPort -Id 5
            $Result.Uri | Should -Match '/api/dcim/front-ports/5/'
        }
    }

    Context "Add-NBDCIMFrontPort" {
        It "Should create a front port" {
            $Result = Add-NBDCIMFrontPort -Device 1 -Name 'FP1' -Type '8p8c' -Rear_Port 1 -Rear_Port_Position 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/front-ports/'
        }
    }

    Context "Set-NBDCIMFrontPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMFrontPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'FP1' }
            }
        }

        It "Should update a front port" {
            $Result = Set-NBDCIMFrontPort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/front-ports/1/'
        }
    }

    Context "Remove-NBDCIMFrontPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMFrontPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'FP1' }
            }
        }

        It "Should remove a front port" {
            $Result = Remove-NBDCIMFrontPort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/front-ports/2/'
        }
    }
    #endregion

    #region RearPorts
    Context "Get-NBDCIMRearPort" {
        It "Should request rear ports" {
            $Result = Get-NBDCIMRearPort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rear-ports/'
        }

        It "Should request a rear port by ID" {
            $Result = Get-NBDCIMRearPort -Id 5
            $Result.Uri | Should -Match '/api/dcim/rear-ports/5/'
        }
    }

    Context "Add-NBDCIMRearPort" {
        It "Should create a rear port" {
            $Result = Add-NBDCIMRearPort -Device 1 -Name 'RP1' -Type '8p8c'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rear-ports/'
        }
    }

    Context "Set-NBDCIMRearPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRearPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'RP1' }
            }
        }

        It "Should update a rear port" {
            $Result = Set-NBDCIMRearPort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/rear-ports/1/'
        }
    }

    Context "Remove-NBDCIMRearPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRearPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'RP1' }
            }
        }

        It "Should remove a rear port" {
            $Result = Remove-NBDCIMRearPort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/rear-ports/2/'
        }
    }
    #endregion

    #region MACAddresses
    Context "Get-NBDCIMMACAddress" {
        It "Should request MAC addresses" {
            $Result = Get-NBDCIMMACAddress
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/mac-addresses/'
        }

        It "Should request a MAC address by ID" {
            $Result = Get-NBDCIMMACAddress -Id 5
            $Result.Uri | Should -Match '/api/dcim/mac-addresses/5/'
        }
    }

    Context "New-NBDCIMMACAddress" {
        It "Should create a MAC address" {
            $Result = New-NBDCIMMACAddress -Mac_Address '00:11:22:33:44:55'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/mac-addresses/'
        }
    }

    Context "Set-NBDCIMMACAddress" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMMACAddress" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Mac_Address' = '00:11:22:33:44:55' }
            }
        }

        It "Should update a MAC address" {
            $Result = Set-NBDCIMMACAddress -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/mac-addresses/1/'
        }
    }

    Context "Remove-NBDCIMMACAddress" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMMACAddress" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Mac_Address' = '00:11:22:33:44:55' }
            }
        }

        It "Should remove a MAC address" {
            $Result = Remove-NBDCIMMACAddress -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/mac-addresses/2/'
        }
    }
    #endregion

    #region VirtualChassis
    Context "Get-NBDCIMVirtualChassis" {
        It "Should request virtual chassis" {
            $Result = Get-NBDCIMVirtualChassis
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/virtual-chassis/'
        }

        It "Should request a virtual chassis by ID" {
            $Result = Get-NBDCIMVirtualChassis -Id 5
            $Result.Uri | Should -Match '/api/dcim/virtual-chassis/5/'
        }
    }

    Context "New-NBDCIMVirtualChassis" {
        It "Should create a virtual chassis" {
            $Result = New-NBDCIMVirtualChassis -Name 'VC1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/virtual-chassis/'
        }
    }

    Context "Set-NBDCIMVirtualChassis" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMVirtualChassis" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'VC1' }
            }
        }

        It "Should update a virtual chassis" {
            $Result = Set-NBDCIMVirtualChassis -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/virtual-chassis/1/'
        }
    }

    Context "Remove-NBDCIMVirtualChassis" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMVirtualChassis" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'VC1' }
            }
        }

        It "Should remove a virtual chassis" {
            $Result = Remove-NBDCIMVirtualChassis -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/virtual-chassis/2/'
        }
    }
    #endregion

    #region VirtualDeviceContexts
    Context "Get-NBDCIMVirtualDeviceContext" {
        It "Should request virtual device contexts" {
            $Result = Get-NBDCIMVirtualDeviceContext
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/virtual-device-contexts/'
        }

        It "Should request a virtual device context by ID" {
            $Result = Get-NBDCIMVirtualDeviceContext -Id 5
            $Result.Uri | Should -Match '/api/dcim/virtual-device-contexts/5/'
        }
    }

    Context "New-NBDCIMVirtualDeviceContext" {
        It "Should create a virtual device context" {
            $Result = New-NBDCIMVirtualDeviceContext -Name 'VDC1' -Device 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/virtual-device-contexts/'
        }
    }

    Context "Set-NBDCIMVirtualDeviceContext" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMVirtualDeviceContext" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'VDC1' }
            }
        }

        It "Should update a virtual device context" {
            $Result = Set-NBDCIMVirtualDeviceContext -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/virtual-device-contexts/1/'
        }
    }

    Context "Remove-NBDCIMVirtualDeviceContext" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMVirtualDeviceContext" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'VDC1' }
            }
        }

        It "Should remove a virtual device context" {
            $Result = Remove-NBDCIMVirtualDeviceContext -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/dcim/virtual-device-contexts/2/'
        }
    }
    #endregion
}
