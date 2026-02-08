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

        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
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
            # By default, config_context is excluded for performance
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?omit=config_context'
        }

        It "Should request with a limit and offset" {
            $Result = Get-NBDCIMDevice -Limit 10 -Offset 100

            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed, so check all are present
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=100'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a query" {
            $Result = Get-NBDCIMDevice -Query 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'q=testdevice'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBDCIMDevice -Query 'test device'

            $Result.Method | Should -Be 'GET'
            # UriBuilder encodes spaces as %20 in the URI
            $Result.Uri | Should -Match 'q=test%20device'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a name" {
            $Result = Get-NBDCIMDevice -Name 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'name=testdevice'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a single ID" {
            $Result = Get-NBDCIMDevice -Id 10

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'dcim/devices/10/'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request a device by ID from the pipeline" {
            $Result = [pscustomobject]@{ 'id' = 10 } | Get-NBDCIMDevice

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'dcim/devices/10/'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with multiple IDs" {
            $Result = Get-NBDCIMDevice -Id 10, 12, 15

            $Result | Should -HaveCount 3
            $Result[0].Method | Should -Be 'GET'
            $Result[0].Uri | Should -Match 'dcim/devices/10/'
            $Result[1].Uri | Should -Match 'dcim/devices/12/'
            $Result[2].Uri | Should -Match 'dcim/devices/15/'
            $Result | ForEach-Object { $_.Uri | Should -Match 'omit=config_context' }
        }

        It "Should request a status" {
            $Result = Get-NBDCIMDevice -Status 'Active'

            $Result.Method | Should -Be 'GET'
            # Status value is passed through to API as-is (no client-side validation)
            $Result.Uri | Should -Match 'status=Active'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should have ValidateSet for Status parameter" {
            # Status parameter now uses ValidateSet for type safety
            $cmd = Get-Command Get-NBDCIMDevice
            $statusParam = $cmd.Parameters['Status']
            $validateSet = $statusParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'active'
        }

        It "Should request devices that are a PDU" {
            $Result = Get-NBDCIMDevice -Is_PDU $True

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'is_pdu=True'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should exclude config_context by default" {
            $Result = Get-NBDCIMDevice

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should not exclude config_context when IncludeConfigContext is specified" {
            $Result = Get-NBDCIMDevice -IncludeConfigContext

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Not -Match 'omit=config_context'
        }

        It "Should request with Brief mode" {
            $Result = Get-NBDCIMDevice -Brief

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'brief=True'
        }

        It "Should request with specific fields" {
            $Result = Get-NBDCIMDevice -Fields 'id','name','status','site.name'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'fields=id(%2C|,)name(%2C|,)status(%2C|,)site.name'
        }

        It "Should combine Brief with exclude config_context" {
            $Result = Get-NBDCIMDevice -Brief

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'brief=True'
            $Result.Uri | Should -Match 'omit=config_context'
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

            Should -Invoke -CommandName "InvokeNetboxRequest" -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'

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
            $Result = New-NBDCIMDevice -Name "newdevice" -Device_Role 4 -Device_Type 10 -Site 1 -Face 'front'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'

            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'newdevice'
            $bodyObj.role | Should -Be 4
            $bodyObj.device_type | Should -Be 10
            $bodyObj.site | Should -Be 1
            $bodyObj.face | Should -Be 'front'
        }

        It "Should have ValidateSet for Status parameter" {
            # Status parameter now uses ValidateSet for type safety
            $cmd = Get-Command New-NBDCIMDevice
            $statusParam = $cmd.Parameters['Status']
            $validateSet = $statusParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'active'
        }

        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
            $inputObjParam = $cmd.Parameters['InputObject']
            $inputObjParam.ParameterSets.Keys | Should -Contain 'Bulk'
        }

        It "Should have BatchSize parameter with validation" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'BatchSize'
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }

        It "Should have Force parameter for bulk mode" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'Force'
        }

        It "Should use Role alias Device_Role for backwards compatibility" {
            $cmd = Get-Command New-NBDCIMDevice
            $roleParam = $cmd.Parameters['Role']
            $roleParam.Aliases | Should -Contain 'Device_Role'
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

            # Uses Id directly without fetching device first (performance optimization #177)
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

        # Note: Array Id parameters are not supported for Set- functions
        # For bulk operations via pipeline, see BulkOperations.Tests.ps1
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

        # Note: Array Id parameters are not supported for Remove- functions
        # For bulk operations via pipeline, see BulkOperations.Tests.ps1

        It "Should remove devices via bulk mode pipeline" {
            # Pipeline triggers bulk mode - Send-NBBulkRequest handles the DELETE
            # Mock InvokeNetboxRequest to return null (DELETE returns no body)
            Mock -CommandName "InvokeNetboxRequest" -ModuleName PowerNetbox -MockWith {
                return $null
            }

            $items = @(
                [pscustomobject]@{ 'Id' = 30 },
                [pscustomobject]@{ 'Id' = 31 }
            )
            $items | Remove-NBDCIMDevice -Force

            # Verify InvokeNetboxRequest was called with DELETE and the bulk endpoint
            Should -Invoke -CommandName "InvokeNetboxRequest" -ModuleName PowerNetbox -ParameterFilter {
                $Method -eq 'DELETE' -and $URI.ToString() -like '*dcim/devices/*' -and $null -ne $Body
            }
        }
    }

    Context "Set-NBDCIMDeviceRole" {
        It "Should update a device role" {
            $Result = Set-NBDCIMDeviceRole -Id 1 -Name 'UpdatedRole' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'UpdatedRole'
        }

        It "Should update a device role with multiple properties" {
            $Result = Set-NBDCIMDeviceRole -Id 2 -Name 'ServerRole' -Color 'ff0000' -VM_Role $true -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/2/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'ServerRole'
            $bodyObj.color | Should -Be 'ff0000'
            $bodyObj.vm_role | Should -Be $true
        }
    }

    Context "Set-NBDCIMDeviceType" {
        It "Should update a device type" {
            $Result = Set-NBDCIMDeviceType -Id 1 -Model 'UpdatedModel' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/device-types/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.model | Should -Be 'UpdatedModel'
        }

        It "Should update a device type with multiple properties" {
            $Result = Set-NBDCIMDeviceType -Id 3 -Manufacturer 5 -U_Height 2 -Is_Full_Depth $true -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/device-types/3/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.manufacturer | Should -Be 5
            $bodyObj.u_height | Should -Be 2
            $bodyObj.is_full_depth | Should -Be $true
        }
    }

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBDCIMDevice'; Parameters = @{ Name = 'whatif-test'; Role = 1; Device_Type = 1; Site = 1 } }
            @{ Command = 'New-NBDCIMDeviceRole'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMDeviceType'; Parameters = @{ Manufacturer = 1; Model = 'whatif-test' } }
            @{ Command = 'Set-NBDCIMDevice'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMDeviceRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMDeviceType'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMDevice'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMDeviceRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMDeviceType'; Parameters = @{ Id = 1 } }
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
