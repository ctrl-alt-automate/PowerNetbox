
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

Describe "DCIM Devices Tests" -Tag 'DCIM', 'Devices' {
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
        $script:NetboxConfig.Choices.DCIM = (Get-Content "/DCIMChoices.json" -ErrorAction Stop | ConvertFrom-Json)

        Context "Get-NBDCIMDevice" {
            It "Should request the default number of devices" {
                $Result = Get-NBDCIMDevice

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a limit and offset" {
                $Result = Get-NBDCIMDevice -Limit 10 -Offset 100

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?offset=100&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a query" {
                $Result = Get-NBDCIMDevice -Query 'testdevice'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?q=testdevice'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with an escaped query" {
                $Result = Get-NBDCIMDevice -Query 'test device'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?q=test+device'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a name" {
                $Result = Get-NBDCIMDevice -Name 'testdevice'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?name=testdevice'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a single ID" {
                $Result = Get-NBDCIMDevice -Id 10

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a device by ID from the pipeline" {
                $Result = [pscustomobject]@{
                    'id' = 10
                } | Get-NBDCIMDevice

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with multiple IDs" {
                $Result = Get-NBDCIMDevice -Id 10, 12, 15

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?id__in=10,12,15'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a status" {
                $Result = Get-NBDCIMDevice -Status 'Active'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?status=1'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should throw for an invalid status" {
                {
                    Get-NBDCIMDevice -Status 'Fake'
                } | Should -Throw
            }

            It "Should request devices that are a PDU" {
                $Result = Get-NBDCIMDevice -Is_PDU $True

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/devices/?is_pdu=True'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }
        }

        Context "Get-NBDCIMDeviceType" {
            It "Should request the default number of devices types" {
                $Result = Get-NBDCIMDeviceType

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a limit and offset" {
                $Result = Get-NBDCIMDeviceType -Limit 10 -Offset 100

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?offset=100&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a query" {
                $Result = Get-NBDCIMDeviceType -Query 'testdevice'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?q=testdevice'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with an escaped query" {
                $Result = Get-NBDCIMDeviceType -Query 'test device'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?q=test+device'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a slug" {
                $Result = Get-NBDCIMDeviceType -Slug 'testdevice'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?slug=testdevice'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a single ID" {
                $Result = Get-NBDCIMDeviceType -Id 10

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with multiple IDs" {
                $Result = Get-NBDCIMDeviceType -Id 10, 12, 15

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?id__in=10,12,15'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a device type that is PDU" {
                $Result = Get-NBDCIMDeviceType -Is_PDU $true

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?is_pdu=True'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }
        }

        Context "Get-NBDCIMDeviceRole" {
            It "Should request the default number of devices types" {
                $Result = Get-NBDCIMDeviceRole

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a device role by Id" {
                $Result = Get-NBDCIMDeviceRole -Id 10

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request multiple roles by Id" {
                $Result = Get-NBDCIMDeviceRole -Id 10, 12

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET', 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/10/', 'https://netbox.domain.com/api/dcim/device-roles/12/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }

            It "Should request single role by Id and color" {
                $Result = Get-NBDCIMDeviceRole -Id 10 -Color '0fab12'

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/10/?color=0fab12'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request multiple roles by Id and color" {
                $Result = Get-NBDCIMDeviceRole -Id 10, 12 -Color '0fab12'

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET', 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/10/?color=0fab12', 'https://netbox.domain.com/api/dcim/device-roles/12/?color=0fab12'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }

            It "Should request with a limit and offset" {
                $Result = Get-NBDCIMDeviceRole -Limit 10 -Offset 100

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?offset=100&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a slug" {
                $Result = Get-NBDCIMDeviceRole -Slug 'testdevice'

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?slug=testdevice'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a name" {
                $Result = Get-NBDCIMDeviceRole -Name 'TestRole'

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?name=TestRole'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request those that are VM role" {
                $Result = Get-NBDCIMDeviceRole -VM_Role $true

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?vm_role=True'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }
        }

        Context "New-NBDCIMDevice" {
            It "Should create a new device" {
                $Result = New-NBDCIMDevice -Name "newdevice" -Device_Role 4 -Device_Type 10 -Site 1 -Face 0

                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"site":1,"face":0,"name":"newdevice","status":1,"device_type":10,"device_role":4}'
            }

            It "Should throw because of an invalid status" {
                {
                    New-NBDCIMDevice -Name "newdevice" -Device_Role 4 -Device_Type 10 -Site 1 -Status 5555
                } | Should -Throw
            }
        }


        Mock -CommandName "Get-NBDCIMDevice" -ModuleName NetboxPSv4 -MockWith {
            return [pscustomobject]@{
                'Id'   = $Id
                'Name' = $Name
            }
        }

        Context "Set-NBDCIMDevice" {
            It "Should set a device to a new name" {
                $Result = Set-NBDCIMDevice -Id 1234 -Name 'newtestname' -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"name":"newtestname"}'
            }

            It "Should set a device with new properties" {
                $Result = Set-NBDCIMDevice -Id 1234 -Name 'newtestname' -Cluster 10 -Platform 20 -Site 15 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"cluster":10,"platform":20,"name":"newtestname","site":15}'
            }

            It "Should set multiple devices with new properties" {
                $Result = Set-NBDCIMDevice -Id 1234, 3214 -Cluster 10 -Platform 20 -Site 15 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/', 'https://netbox.domain.com/api/dcim/devices/3214/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"cluster":10,"platform":20,"site":15}', '{"cluster":10,"platform":20,"site":15}'
            }

            It "Should set multiple devices with new properties from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'id' = 4432
                    },
                    [pscustomobject]@{
                        'id' = 3241
                    }
                ) | Set-NBDCIMDevice -Cluster 10 -Platform 20 -Site 15 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/4432/', 'https://netbox.domain.com/api/dcim/devices/3241/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"cluster":10,"platform":20,"site":15}', '{"cluster":10,"platform":20,"site":15}'
            }
        }

        Context "Remove-NBDCIMDevice" {
            It "Should remove a device" {
                $Result = Remove-NBDCIMDevice -Id 10 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should remove multiple devices" {
                $Result = Remove-NBDCIMDevice -Id 10, 12 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/', 'https://netbox.domain.com/api/dcim/devices/12/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }

            It "Should remove a device from the pipeline" {
                $Result = Get-NBDCIMDevice -Id 20 | Remove-NBDCIMDevice -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/20/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should remove mulitple devices from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'Id' = 30
                    },
                    [pscustomobject]@{
                        'Id' = 40
                    }
                ) | Remove-NBDCIMDevice -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/30/', 'https://netbox.domain.com/api/dcim/devices/40/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }
        }
    }
}































