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

Describe "Bulk Operations Tests" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith {
            return $true
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

        InModuleScope -ModuleName 'PowerNetbox' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
            $script:NetboxConfig.Choices.DCIM = (Get-Content "$TestPath/DCIMChoices.json" -ErrorAction Stop | ConvertFrom-Json)
        }
    }

    Context "BulkOperationResult Class" {
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

    Context "Send-NBBulkRequest Helper" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                # Simulate bulk API response - return array of created items
                $body = $Body | ConvertFrom-Json
                $response = @()
                $id = 100
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
        }

        It "Should send items in batches" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = 1..5 | ForEach-Object {
                    [PSCustomObject]@{
                        name = "device$_"
                        role = 1
                        device_type = 1
                        site = 1
                    }
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
                $items = @([PSCustomObject]@{
                    name = "single-device"
                    role = 1
                    device_type = 1
                    site = 1
                })

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 50

                $result.SuccessCount | Should -Be 1
            }
        }
    }

    Context "New-NBDCIMDevice Bulk Mode" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                # Check if body is an array (bulk) or object (single)
                $body = $Body | ConvertFrom-Json
                if ($body -is [array]) {
                    # Bulk response - return array
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
                    # Single item response
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

        It "Should create a single device (backwards compatible)" {
            $result = New-NBDCIMDevice -Name "single-device" -Role 1 -Device_Type 1 -Site 1 -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be "single-device"
            $result.id | Should -Be 100

            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -ModuleName 'PowerNetbox'
        }

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
                    Device_Role = 5  # Should be converted to 'role'
                    Device_Type = 1
                    Site = 1
                }
            )

            $results = $devices | New-NBDCIMDevice -BatchSize 10 -Force

            $results | Should -Not -BeNullOrEmpty
            $results[0].role | Should -Be 5
        }

        It "Should use parameter sets correctly" {
            # Verify Single parameter set
            $singleCmd = Get-Command New-NBDCIMDevice
            $singleParams = $singleCmd.ParameterSets | Where-Object { $_.Name -eq 'Single' }
            $singleParams | Should -Not -BeNullOrEmpty

            # Verify Bulk parameter set
            $bulkParams = $singleCmd.ParameterSets | Where-Object { $_.Name -eq 'Bulk' }
            $bulkParams | Should -Not -BeNullOrEmpty

            # Verify InputObject is in Bulk set
            $inputObjParam = $singleCmd.Parameters['InputObject']
            $inputObjParam.ParameterSets.Keys | Should -Contain 'Bulk'
        }

        It "Should validate BatchSize range" {
            $cmd = Get-Command New-NBDCIMDevice
            $batchSizeParam = $cmd.Parameters['BatchSize']

            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }

        It "Should support -Force switch for bulk operations" {
            $devices = @([PSCustomObject]@{
                Name = "force-test"
                Role = 1
                Device_Type = 1
                Site = 1
            })

            # With -Force, should not prompt for confirmation
            { $devices | New-NBDCIMDevice -BatchSize 10 -Force } | Should -Not -Throw
        }
    }

    Context "Bulk Operations Error Handling" {
        It "Should handle API errors gracefully" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw "API Error: Validation failed"
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = @([PSCustomObject]@{
                    name = "error-device"
                    role = 1
                    device_type = 1
                    site = 1
                })

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST

                $result.HasErrors | Should -BeTrue
                $result.FailureCount | Should -Be 1
                $result.SuccessCount | Should -Be 0
            }
        }
    }
}

Describe "Bulk Operations Integration Tests" -Tag 'Bulk', 'Integration', 'Live' {
    BeforeAll {
        $skipTests = $true
        if ($env:NETBOX_HOST -and $env:NETBOX_TOKEN) {
            $skipTests = $false
            Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
            $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
            Import-Module $ModulePath -Force

            $cred = [PSCredential]::new('api', (ConvertTo-SecureString $env:NETBOX_TOKEN -AsPlainText -Force))
            Connect-NBAPI -Hostname $env:NETBOX_HOST -Credential $cred

            # Get test prerequisites
            $script:TestSite = Get-NBDCIMSite -Limit 1 | Select-Object -First 1
            $script:TestRole = Get-NBDCIMDeviceRole -Limit 1 | Select-Object -First 1
            $script:TestType = Get-NBDCIMDeviceType -Limit 1 | Select-Object -First 1
        }
    }

    It "Should create and clean up devices in bulk (live API)" -Skip:$skipTests {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $devices = 1..5 | ForEach-Object {
            [PSCustomObject]@{
                Name = "bulk-int-test-$_-$timestamp"
                Role = $script:TestRole.id
                Device_Type = $script:TestType.id
                Site = $script:TestSite.id
            }
        }

        # Create devices in bulk
        $results = $devices | New-NBDCIMDevice -BatchSize 3 -Force

        try {
            $results.Count | Should -Be 5
            $results | ForEach-Object { $_.id | Should -BeGreaterThan 0 }
        }
        finally {
            # Cleanup
            $results | ForEach-Object {
                Remove-NBDCIMDevice -Id $_.id -Confirm:$false
            }
        }
    }

    It "Should measure performance improvement (live API)" -Skip:$skipTests {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $deviceCount = 10

        # Create device objects
        $devices = 1..$deviceCount | ForEach-Object {
            [PSCustomObject]@{
                Name = "perf-test-$_-$timestamp"
                Role = $script:TestRole.id
                Device_Type = $script:TestType.id
                Site = $script:TestSite.id
            }
        }

        # Measure bulk creation time
        $bulkTime = Measure-Command {
            $bulkResults = $devices | New-NBDCIMDevice -BatchSize 50 -Force
        }

        try {
            $bulkResults.Count | Should -Be $deviceCount
            Write-Host "Bulk creation of $deviceCount devices: $($bulkTime.TotalMilliseconds)ms"
        }
        finally {
            # Cleanup
            $bulkResults | ForEach-Object {
                Remove-NBDCIMDevice -Id $_.id -Confirm:$false
            }
        }
    }
}
