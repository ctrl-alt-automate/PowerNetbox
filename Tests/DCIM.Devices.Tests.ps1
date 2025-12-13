[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    # Store PSScriptRoot for use in InModuleScope
    $script:TestPath = $PSScriptRoot
}

Describe "DCIM Devices Tests" -Tag 'DCIM', 'Devices' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith {
            return $true
        }

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

        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith {
            return 'netbox.domain.com'
        }

        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith {
            return 30
        }

        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith {
            return @{}
        }

        # Set up module internal state and load choices data
        InModuleScope -ModuleName 'PowerNetbox' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
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
            # Parameter order in hashtables is not guaranteed, so check both are present
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=100'
        }

        It "Should request with a query" {
            $Result = Get-NBDCIMDevice -Query 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?q=testdevice'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBDCIMDevice -Query 'test device'

            $Result.Method | Should -Be 'GET'
            # Module doesn't URL-encode spaces in query strings
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?q=test device'
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
            # Commas may or may not be URL-encoded depending on PS version
            $Result.Uri | Should -Match 'id__in=10(%2C|,)12(%2C|,)15'
        }

        It "Should request a status" {
            $Result = Get-NBDCIMDevice -Status 'Active'

            $Result.Method | Should -Be 'GET'
            # Status value is passed through to API as-is (no client-side validation)
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?status=Active'
        }

        It "Should pass invalid status to API" {
            # Invalid status values are now passed through to the API
            # The API will return an error, not the client
            $Result = Get-NBDCIMDevice -Status 'Fake'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?status=Fake'
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
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=100'
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

            Should -Invoke -CommandName "Invoke-RestMethod" -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'

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

            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'

            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'newdevice'
            $bodyObj.device_role | Should -Be 4
            $bodyObj.device_type | Should -Be 10
            $bodyObj.site | Should -Be 1
            $bodyObj.face | Should -Be 0
        }

        It "Should pass invalid status to API" {
            # Invalid status values are now passed through to the API
            $Result = New-NBDCIMDevice -Name "newdevice" -Device_Role 4 -Device_Type 10 -Site 1 -Status 5555
            $Result.Method | Should -Be 'POST'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.status | Should -Be 5555
        }
    }

    Context "Set-NBDCIMDevice" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDevice" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{
                    'Id'   = $Id
                    'Name' = $Name
                }
            }
        }

        It "Should set a device to a new name" {
            $Result = Set-NBDCIMDevice -Id 1234 -Name 'newtestname' -Force

            Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'

            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/'
            $Result.Body | Should -Be '{"name":"newtestname"}'
        }

        It "Should set a device with new properties" {
            $Result = Set-NBDCIMDevice -Id 1234 -Name 'newtestname' -Cluster 10 -Platform 20 -Site 15 -Force

            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'newtestname'
            $bodyObj.cluster | Should -Be 10
            $bodyObj.platform | Should -Be 20
            $bodyObj.site | Should -Be 15
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
            Mock -CommandName "Get-NBDCIMDevice" -ModuleName PowerNetbox -MockWith {
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
