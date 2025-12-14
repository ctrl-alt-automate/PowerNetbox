[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    $script:TestPath = $PSScriptRoot
}

Describe "BulkOperationResult Class" -Tag 'Bulk', 'Unit' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Basic Operations" {
        It "Should create a new BulkOperationResult" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()

                $result | Should -Not -BeNullOrEmpty
                $result.SuccessCount | Should -Be 0
                $result.FailureCount | Should -Be 0
                $result.TotalCount | Should -Be 0
                $result.HasErrors | Should -BeFalse
            }
        }

        It "Should track successful items" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()
                $item = [PSCustomObject]@{ id = 1; name = "test" }

                $result.AddSuccess($item)

                $result.SuccessCount | Should -Be 1
                $result.TotalCount | Should -Be 1
                $result.HasErrors | Should -BeFalse
                $result.Succeeded.Count | Should -Be 1
            }
        }

        It "Should track failed items" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()
                $item = [PSCustomObject]@{ name = "test" }

                $result.AddFailure($item, "Validation error")

                $result.FailureCount | Should -Be 1
                $result.TotalCount | Should -Be 1
                $result.HasErrors | Should -BeTrue
                $result.Failed.Count | Should -Be 1
                $result.Errors.Count | Should -Be 1
            }
        }

        It "Should track duration after completion" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()
                Start-Sleep -Milliseconds 50
                $result.Complete()

                $result.Duration.TotalMilliseconds | Should -BeGreaterThan 40
            }
        }

        It "Should generate summary message" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()
                $result.AddSuccess([PSCustomObject]@{ id = 1 })
                $result.AddSuccess([PSCustomObject]@{ id = 2 })
                $result.AddFailure([PSCustomObject]@{ name = "fail" }, "Error")
                $result.Complete()

                $summary = $result.GetSummary()

                $summary | Should -Match "2/3 succeeded"
                $summary | Should -Match "1 failed"
            }
        }
    }
}

Describe "Send-NBBulkRequest Helper" -Tag 'Bulk', 'Unit' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
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

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            $response = @()
            $id = 100
            foreach ($item in $body) {
                $response += [PSCustomObject]@{
                    id = $id++
                    name = $item.name
                }
            }
            return $response
        }
    }

    Context "Batching Behavior" {
        It "Should send items in batches" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = 1..5 | ForEach-Object {
                    [PSCustomObject]@{ name = "device$_" }
                }

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 3

                $result | Should -Not -BeNullOrEmpty
                $result.SuccessCount | Should -Be 5
                $result.FailureCount | Should -Be 0
            }

            # With batch size 3 and 5 items: should be 2 API calls (3 + 2)
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 2 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should return empty result for empty items" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = @()

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST

                $result.TotalCount | Should -Be 0
                $result.SuccessCount | Should -Be 0
            }
        }

        It "Should handle single item" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = @([PSCustomObject]@{ name = "single-device" })

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 50

                $result.SuccessCount | Should -Be 1
            }
        }
    }

    Context "Error Handling" {
        It "Should handle API errors gracefully" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw "API Error: Validation failed"
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = @([PSCustomObject]@{ name = "error-device" })

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST

                $result.HasErrors | Should -BeTrue
                $result.FailureCount | Should -Be 1
                $result.SuccessCount | Should -Be 0
            }
        }
    }
}

Describe "New-NBDCIMDevice Bulk Mode" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
            $script:NetboxConfig.Choices.DCIM = (Get-Content "$TestPath/DCIMChoices.json" -ErrorAction Stop | ConvertFrom-Json)
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 200
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        name = $item.name
                        role = $item.role
                        device_type = $item.device_type
                        site = $item.site
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    name = $body.name
                    role = $body.role
                    device_type = $body.device_type
                    site = $body.site
                }
            }
        }
    }

    Context "Parameter Sets" {
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
    }

    Context "Bulk Operations" {
        It "Should create devices in bulk via pipeline" {
            $devices = 1..3 | ForEach-Object {
                [PSCustomObject]@{
                    Name = "bulk-device-$_"
                    Role = 1
                    Device_Type = 1
                    Site = 1
                }
            }

            $results = $devices | New-NBDCIMDevice -BatchSize 10 -Force

            $results.Count | Should -Be 3
            $results[0].name | Should -Be "bulk-device-1"
            $results[1].name | Should -Be "bulk-device-2"
            $results[2].name | Should -Be "bulk-device-3"
        }

        It "Should split large batches into multiple API calls" {
            $devices = 1..7 | ForEach-Object {
                [PSCustomObject]@{
                    Name = "batch-device-$_"
                    Role = 1
                    Device_Type = 1
                    Site = 1
                }
            }

            $results = $devices | New-NBDCIMDevice -BatchSize 3 -Force

            $results.Count | Should -Be 7

            # 7 items with batch size 3 = 3 API calls (3 + 3 + 1)
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 3 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should handle Device_Role alias in bulk mode" {
            $devices = @(
                [PSCustomObject]@{
                    Name = "alias-test"
                    Device_Role = 5
                    Device_Type = 1
                    Site = 1
                }
            )

            $results = $devices | New-NBDCIMDevice -BatchSize 10 -Force

            $results | Should -Not -BeNullOrEmpty
            $results[0].role | Should -Be 5
        }
    }
}

Describe "New-NBDCIMInterface Bulk Mode" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
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

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        device = $item.device
                        name = $item.name
                        type = $item.type
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    device = $body.device
                    name = $body.name
                    type = $body.type
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBDCIMInterface
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command New-NBDCIMInterface
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
        }

        It "Should have BatchSize with valid range" {
            $cmd = Get-Command New-NBDCIMInterface
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }
    }

    Context "Bulk Operations" {
        It "Should create interfaces in bulk" {
            $interfaces = 0..4 | ForEach-Object {
                [PSCustomObject]@{
                    Device = 42
                    Name = "eth$_"
                    Type = "1000base-t"
                }
            }

            $results = $interfaces | New-NBDCIMInterface -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }

        It "Should batch large requests" {
            $interfaces = 0..9 | ForEach-Object {
                [PSCustomObject]@{ Device = 42; Name = "port$_"; Type = "1000base-t" }
            }

            $results = $interfaces | New-NBDCIMInterface -BatchSize 3 -Force

            # 10 items / 3 batch size = 4 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 4 -Exactly -ModuleName 'PowerNetbox'
        }
    }
}

Describe "New-NBIPAMPrefix Bulk Mode" -Tag 'Bulk', 'IPAM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
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

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        prefix = $item.prefix
                        status = $item.status
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    prefix = $body.prefix
                    status = $body.status
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBIPAMPrefix
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }
    }

    Context "Bulk Operations" {
        It "Should create prefixes in bulk" {
            $prefixes = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    Prefix = "10.$_.0.0/24"
                    Status = "active"
                }
            }

            $results = $prefixes | New-NBIPAMPrefix -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }
    }
}

Describe "New-NBVirtualMachine Bulk Mode" -Tag 'Bulk', 'Virtualization' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
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

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        name = $item.name
                        cluster = $item.cluster
                        vcpus = $item.vcpus
                        memory = $item.memory
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    name = $body.name
                    cluster = $body.cluster
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBVirtualMachine
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }
    }

    Context "Bulk Operations" {
        It "Should create VMs in bulk" {
            $vms = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    Name = "vm-$_"
                    Cluster = 1
                    vCPUs = 2
                    Memory = 4096
                }
            }

            $results = $vms | New-NBVirtualMachine -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }

        It "Should handle Device_Role alias" {
            $vm = [PSCustomObject]@{
                Name = "alias-vm"
                Device_Role = 3
                Cluster = 1
            }

            $results = @($vm) | New-NBVirtualMachine -Force

            $results | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "New-NBIPAMVLAN Bulk Mode" -Tag 'Bulk', 'IPAM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
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

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        vid = $item.vid
                        name = $item.name
                        status = $item.status
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    vid = $body.vid
                    name = $body.name
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBIPAMVLAN
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should validate VID range in single mode" {
            $cmd = Get-Command New-NBIPAMVLAN
            $vidParam = $cmd.Parameters['VID']
            $validateRange = $vidParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 4094
        }
    }

    Context "Bulk Operations" {
        It "Should create VLANs in bulk" {
            $vlans = 100..104 | ForEach-Object {
                [PSCustomObject]@{
                    VID = $_
                    Name = "VLAN$_"
                    Status = "active"
                }
            }

            $results = $vlans | New-NBIPAMVLAN -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }
    }
}

Describe "New-NBVirtualMachineInterface Bulk Mode" -Tag 'Bulk', 'Virtualization' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
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

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        virtual_machine = $item.virtual_machine
                        name = $item.name
                        enabled = $item.enabled
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    virtual_machine = $body.virtual_machine
                    name = $body.name
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBVirtualMachineInterface
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }
    }

    Context "Bulk Operations" {
        It "Should create VM interfaces in bulk" {
            $interfaces = 0..4 | ForEach-Object {
                [PSCustomObject]@{
                    Virtual_Machine = 123
                    Name = "eth$_"
                }
            }

            $results = $interfaces | New-NBVirtualMachineInterface -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }

        It "Should default enabled to true in bulk mode" {
            # Test that the function adds enabled=true by default
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                param($Body)
                $body = $Body | ConvertFrom-Json
                # Verify enabled was set to true
                $body[0].enabled | Should -Be $true
                return @([PSCustomObject]@{
                    id = 100
                    virtual_machine = 123
                    name = "eth0"
                    enabled = $body[0].enabled
                })
            }

            $interface = [PSCustomObject]@{
                Virtual_Machine = 123
                Name = "eth0"
            }

            $results = @($interface) | New-NBVirtualMachineInterface -Force

            $results | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Set-NBDCIMDevice Bulk Mode" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
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

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $item.id
                        name = if ($item.name) { $item.name } else { "device-$($item.id)" }
                        status = $item.status
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = $body.id
                    name = $body.name
                    status = $body.status
                }
            }
        }

        Mock -CommandName 'Get-NBDCIMDevice' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCustomObject]@{
                Id = $Id
                Name = "device-$Id"
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command Set-NBDCIMDevice
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have Medium ConfirmImpact" {
            $cmd = Get-Command Set-NBDCIMDevice
            $attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $attr.ConfirmImpact | Should -Be 'Medium'
        }
    }

    Context "Bulk Operations" {
        It "Should update devices in bulk" {
            $updates = @(
                [PSCustomObject]@{ Id = 100; Status = "active" }
                [PSCustomObject]@{ Id = 101; Status = "active" }
                [PSCustomObject]@{ Id = 102; Status = "planned" }
            )

            $results = $updates | Set-NBDCIMDevice -Force

            $results.Count | Should -Be 3
        }

        It "Should require Id property" {
            $invalidObj = [PSCustomObject]@{ Name = "no-id"; Status = "active" }

            { @($invalidObj) | Set-NBDCIMDevice -Force -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe "Remove-NBDCIMDevice Bulk Mode" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
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

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            # DELETE returns null on success
            return $null
        }

        Mock -CommandName 'Get-NBDCIMDevice' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCustomObject]@{
                Id = $Id
                Name = "device-$Id"
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command Remove-NBDCIMDevice
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have High ConfirmImpact" {
            $cmd = Get-Command Remove-NBDCIMDevice
            $attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $attr.ConfirmImpact | Should -Be 'High'
        }
    }

    Context "Bulk Operations" {
        It "Should delete devices in bulk" {
            $devices = @(
                [PSCustomObject]@{ Id = 100; Name = "device-100" }
                [PSCustomObject]@{ Id = 101; Name = "device-101" }
            )

            { $devices | Remove-NBDCIMDevice -Force } | Should -Not -Throw
        }

        It "Should require Id property" {
            $invalidObj = [PSCustomObject]@{ Name = "no-id" }

            { @($invalidObj) | Remove-NBDCIMDevice -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should batch delete requests" {
            $devices = 1..10 | ForEach-Object {
                [PSCustomObject]@{ Id = $_ }
            }

            $devices | Remove-NBDCIMDevice -BatchSize 3 -Force

            # 10 items / 3 batch size = 4 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 4 -Exactly -ModuleName 'PowerNetbox'
        }
    }
}

Describe "Bulk Operations Live Integration Tests" -Tag 'Bulk', 'Integration', 'Live' -Skip:(-not ($env:NETBOX_HOST -and $env:NETBOX_TOKEN)) {
    BeforeAll {
        Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
        $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
        Import-Module $ModulePath -Force

        $cred = [PSCredential]::new('api', (ConvertTo-SecureString $env:NETBOX_TOKEN -AsPlainText -Force))
        Connect-NBAPI -Hostname $env:NETBOX_HOST -Credential $cred

        # Get test prerequisites
        $script:TestSite = Get-NBDCIMSite -Limit 1 | Select-Object -First 1
        $script:TestRole = Get-NBDCIMDeviceRole -Limit 1 | Select-Object -First 1
        $script:TestType = Get-NBDCIMDeviceType -Limit 1 | Select-Object -First 1
        $script:TestCluster = Get-NBVirtualizationCluster -Limit 1 | Select-Object -First 1
        $script:skipTests = $false
    }

    It "Should bulk create and delete devices (live)" {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $devices = 1..5 | ForEach-Object {
            [PSCustomObject]@{
                Name = "bulk-test-$_-$timestamp"
                Role = $script:TestRole.id
                Device_Type = $script:TestType.id
                Site = $script:TestSite.id
            }
        }

        # Bulk create
        $created = $devices | New-NBDCIMDevice -BatchSize 3 -Force

        try {
            $created.Count | Should -Be 5
            $created | ForEach-Object { $_.id | Should -BeGreaterThan 0 }
        }
        finally {
            # Bulk delete cleanup
            $created | Remove-NBDCIMDevice -Force
        }
    }

    It "Should bulk create VMs (live)" -Skip:(-not $script:TestCluster) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $vms = 1..3 | ForEach-Object {
            [PSCustomObject]@{
                Name = "bulk-vm-$_-$timestamp"
                Cluster = $script:TestCluster.id
                vCPUs = 2
                Memory = 2048
            }
        }

        $created = $vms | New-NBVirtualMachine -BatchSize 10 -Force

        try {
            $created.Count | Should -Be 3
        }
        finally {
            # Cleanup
            $created | ForEach-Object {
                Remove-NBVirtualMachine -Id $_.id -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It "Should bulk update devices (live)" {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"

        # Create test devices first
        $devices = 1..3 | ForEach-Object {
            [PSCustomObject]@{
                Name = "bulk-update-$_-$timestamp"
                Role = $script:TestRole.id
                Device_Type = $script:TestType.id
                Site = $script:TestSite.id
                Status = "planned"
            }
        }

        $created = $devices | New-NBDCIMDevice -BatchSize 10 -Force

        try {
            # Bulk update
            $updates = $created | ForEach-Object {
                [PSCustomObject]@{
                    Id = $_.id
                    Status = "active"
                    Comments = "Bulk updated at $timestamp"
                }
            }

            $updated = $updates | Set-NBDCIMDevice -Force

            $updated.Count | Should -Be 3
            $updated | ForEach-Object { $_.status.value | Should -Be "active" }
        }
        finally {
            # Cleanup
            $created | Remove-NBDCIMDevice -Force
        }
    }
}
