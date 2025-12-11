[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module NetboxPSv4 -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path $PSScriptRoot ".." "NetboxPSv4" "NetboxPSv4.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    # Store PSScriptRoot for use in InModuleScope
    $script:TestPath = $PSScriptRoot
}

Describe "DCIM Devices Tests" -Tag 'DCIM', 'Devices' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'NetboxPSv4' -MockWith {
            return $true
        }

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

        Mock -CommandName 'Get-NBHostname' -ModuleName 'NetboxPSv4' -MockWith {
            return 'netbox.domain.com'
        }

        # Load choices data into module scope
        InModuleScope -ModuleName 'NetboxPSv4' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Choices.DCIM = (Get-Content "$TestPath/DCIMChoices.json" -ErrorAction Stop | ConvertFrom-Json)
        }
    }

    Context "Get-NBDCIMDevice" {
        It "Should request the default number of devices" {
            $Result = Get-NBDCIMDevice

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/'
            $Result.Headers.Keys.Count | Should -BeExactly 1
        }

        It "Should request with a limit and offset" {
            $Result = Get-NBDCIMDevice -Limit 10 -Offset 100

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?offset=100&limit=10'
        }

        It "Should request with a query" {
            $Result = Get-NBDCIMDevice -Query 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?q=testdevice'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBDCIMDevice -Query 'test device'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?q=test+device'
        }

        It "Should request with a name" {
            $Result = Get-NBDCIMDevice -Name 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?name=testdevice'
        }

        It "Should request with a single ID" {
            $Result = Get-NBDCIMDevice -Id 10

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/'
        }

        It "Should request a device by ID from the pipeline" {
            $Result = [pscustomobject]@{ 'id' = 10 } | Get-NBDCIMDevice

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/'
        }

        It "Should request with multiple IDs" {
            $Result = Get-NBDCIMDevice -Id 10, 12, 15

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?id__in=10,12,15'
        }

        It "Should request a status" {
            $Result = Get-NBDCIMDevice -Status 'Active'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?status=1'
        }

        It "Should throw for an invalid status" {
            { Get-NBDCIMDevice -Status 'Fake' } | Should -Throw
        }

        It "Should request devices that are a PDU" {
            $Result = Get-NBDCIMDevice -Is_PDU $True

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/devices/?is_pdu=True'
        }
    }

    Context "Get-NBDCIMDeviceType" {
        It "Should request the default number of device types" {
            $Result = Get-NBDCIMDeviceType

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/'
        }

        It "Should request with a limit and offset" {
            $Result = Get-NBDCIMDeviceType -Limit 10 -Offset 100

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?offset=100&limit=10'
        }

        It "Should request with a slug" {
            $Result = Get-NBDCIMDeviceType -Slug 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?slug=testdevice'
        }

        It "Should request with a single ID" {
            $Result = Get-NBDCIMDeviceType -Id 10

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/10/'
        }

        It "Should request a device type that is PDU" {
            $Result = Get-NBDCIMDeviceType -Is_PDU $true

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?is_pdu=True'
        }
    }

    Context "Get-NBDCIMDeviceRole" {
        It "Should request the default number of device roles" {
            $Result = Get-NBDCIMDeviceRole

            Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly -ModuleName 'NetboxPSv4'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/'
        }

        It "Should request a device role by Id" {
            $Result = Get-NBDCIMDeviceRole -Id 10

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/10/'
        }

        It "Should request with a slug" {
            $Result = Get-NBDCIMDeviceRole -Slug 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?slug=testdevice'
        }

        It "Should request with a name" {
            $Result = Get-NBDCIMDeviceRole -Name 'TestRole'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?name=TestRole'
        }

        It "Should request those that are VM role" {
            $Result = Get-NBDCIMDeviceRole -VM_Role $true

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?vm_role=True'
        }
    }

    Context "New-NBDCIMDevice" {
        It "Should create a new device" {
            $Result = New-NBDCIMDevice -Name "newdevice" -Device_Role 4 -Device_Type 10 -Site 1 -Face 0

            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly -ModuleName 'NetboxPSv4'

            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/'
            $Result.Body | Should -Be '{"site":1,"face":0,"name":"newdevice","status":1,"device_type":10,"device_role":4}'
        }

        It "Should throw because of an invalid status" {
            { New-NBDCIMDevice -Name "newdevice" -Device_Role 4 -Device_Type 10 -Site 1 -Status 5555 } | Should -Throw
        }
    }

    Context "Set-NBDCIMDevice" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDevice" -ModuleName NetboxPSv4 -MockWith {
                return [pscustomobject]@{
                    'Id'   = $Id
                    'Name' = $Name
                }
            }
        }

        It "Should set a device to a new name" {
            $Result = Set-NBDCIMDevice -Id 1234 -Name 'newtestname' -Force

            Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 1 -Scope 'It' -Exactly -ModuleName 'NetboxPSv4'

            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/'
            $Result.Body | Should -Be '{"name":"newtestname"}'
        }

        It "Should set a device with new properties" {
            $Result = Set-NBDCIMDevice -Id 1234 -Name 'newtestname' -Cluster 10 -Platform 20 -Site 15 -Force

            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/'
            $Result.Body | Should -Be '{"cluster":10,"platform":20,"name":"newtestname","site":15}'
        }

        It "Should set multiple devices from the pipeline" {
            $Result = @(
                [pscustomobject]@{ 'id' = 4432 },
                [pscustomobject]@{ 'id' = 3241 }
            ) | Set-NBDCIMDevice -Cluster 10 -Platform 20 -Site 15 -Force

            $Result.Method | Should -Be 'PATCH', 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/4432/', 'https://netbox.domain.com/api/dcim/devices/3241/'
        }
    }

    Context "Remove-NBDCIMDevice" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDevice" -ModuleName NetboxPSv4 -MockWith {
                return [pscustomobject]@{
                    'Id'   = $Id
                    'Name' = $Name
                }
            }
        }

        It "Should remove a device" {
            $Result = Remove-NBDCIMDevice -Id 10 -Force

            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/'
        }

        It "Should remove multiple devices" {
            $Result = Remove-NBDCIMDevice -Id 10, 12 -Force

            $Result.Method | Should -Be 'DELETE', 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/', 'https://netbox.domain.com/api/dcim/devices/12/'
        }

        It "Should remove a device from the pipeline" {
            $Result = [pscustomobject]@{ 'Id' = 30 } | Remove-NBDCIMDevice -Force

            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/30/'
        }
    }
}
