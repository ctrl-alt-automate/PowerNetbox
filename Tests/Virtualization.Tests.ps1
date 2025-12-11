
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
)
Import-Module Pester
Remove-Module NetboxPS -Force -ErrorAction SilentlyContinue

$ModulePath = "$PSScriptRoot\..\dist\NetboxPS.psd1"

if (Test-Path $ModulePath) {
    Import-Module $ModulePath -ErrorAction Stop
}

Describe -Name "Virtualization tests" -Tag 'Virtualization' -Fixture {
    Mock -CommandName 'CheckNetboxIsConnected' -Verifiable -ModuleName 'NetboxPS' -MockWith {
        return $true
    }

    Mock -CommandName 'Invoke-RestMethod' -Verifiable -ModuleName 'NetboxPS' -MockWith {
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

    Mock -CommandName 'Get-NBCredential' -Verifiable -ModuleName 'NetboxPS' -MockWith {
        return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
    }

    Mock -CommandName 'Get-NBHostname' -Verifiable -ModuleName 'NetboxPS' -MockWith {
        return 'netbox.domain.com'
    }

    InModuleScope -ModuleName 'NetboxPS' -ScriptBlock {
        $script:NetboxConfig.Choices.Virtualization = (Get-Content "$PSScriptRoot\VirtualizationChoices.json" -ErrorAction Stop | ConvertFrom-Json)

        Context -Name "Get-NBVirtualMachine" -Fixture {
            It "Should request the default number of VMs" {
                $Result = Get-NBVirtualMachine

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with limit and offset" {
                $Result = Get-NBVirtualMachine -Limit 10 -Offset 12

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/?offset=12&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a query" {
                $Result = Get-NBVirtualMachine -Query 'testvm'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/?q=testvm'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with an escaped query" {
                $Result = Get-NBVirtualMachine -Query 'test vm'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/?q=test+vm'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a name" {
                $Result = Get-NBVirtualMachine -Name 'testvm'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/?name=testvm'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a single ID" {
                $Result = Get-NBVirtualMachine -Id 10

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with multiple IDs" {
                $Result = Get-NBVirtualMachine -Id 10, 12, 15

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/?id__in=10,12,15'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a status" {
                $Result = Get-NBVirtualMachine -Status 'Active'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/?status=1'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should throw for an invalid status" {
                { Get-NBVirtualMachine -Status 'Fake' } | Should -Throw
            }
        }

        Context -Name "Get-NBVirtualMachineInterface" -Fixture {
            It "Should request the default number of interfaces" {
                $Result = Get-NBVirtualMachineInterface

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a limit and offset" {
                $Result = Get-NBVirtualMachineInterface -Limit 10 -Offset 12

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/?offset=12&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a interface with a specific ID" {
                $Result = Get-NBVirtualMachineInterface -Id 10

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request a name" {
                $Result = Get-NBVirtualMachineInterface -Name 'Ethernet0'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/?name=Ethernet0'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a VM ID" {
                $Result = Get-NBVirtualMachineInterface -Virtual_Machine_Id 10

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/?virtual_machine_id=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with Enabled" {
                $Result = Get-NBVirtualMachineInterface -Enabled $true

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/?enabled=true'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }
        }

        Context -Name "Get-NBVirtualMachineCluster" -Fixture {
            It "Should request the default number of clusters" {
                $Result = Get-NBVirtualizationCluster

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with limit and offset" {
                $Result = Get-NBVirtualizationCluster -Limit 10 -Offset 12

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/?offset=12&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a query" {
                $Result = Get-NBVirtualizationCluster -Query 'testcluster'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/?q=testcluster'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with an escaped query" {
                $Result = Get-NBVirtualizationCluster -Query 'test cluster'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/?q=test+cluster'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a name" {
                $Result = Get-NBVirtualizationCluster -Name 'testcluster'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/?name=testcluster'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a single ID" {
                $Result = Get-NBVirtualizationCluster -Id 10

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with multiple IDs" {
                $Result = Get-NBVirtualizationCluster -Id 10, 12, 15

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/?id__in=10,12,15'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }
        }

        Context -Name "Get-NBVirtualMachineClusterGroup" -Fixture {
            It "Should request the default number of cluster groups" {
                $Result = Get-NBVirtualizationClusterGroup

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-groups/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with limit and offset" {
                $Result = Get-NBVirtualizationClusterGroup -Limit 10 -Offset 12

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-groups/?offset=12&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a name" {
                $Result = Get-NBVirtualizationClusterGroup -Name 'testclustergroup'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-groups/?name=testclustergroup'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a slug" {
                $Result = Get-NBVirtualizationClusterGroup -Slug 'test-cluster-group'

                Assert-VerifiableMock

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-groups/?slug=test-cluster-group'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }
        }

        Context -Name "New-NBVirtualMachine" -Fixture {
            It "Should create a basic VM" {
                $Result = New-NBVirtualMachine -Name 'testvm' -Cluster 1

                Assert-VerifiableMock

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"cluster":1,"name":"testvm","status":1}'
            }

            It "Should create a VM with CPUs, Memory, Disk, tenancy, and comments" {
                $Result = New-NBVirtualMachine -Name 'testvm' -Cluster 1 -Status Active -vCPUs 4 -Memory 4096 -Tenant 11 -Disk 50 -Comments "these are comments"

                Assert-VerifiableMock

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"tenant":11,"comments":"these are comments","disk":50,"memory":4096,"name":"testvm","cluster":1,"status":1,"vcpus":4}'
            }

            It "Should throw because of an invalid status" {
                { New-NBVirtualMachine -Name 'testvm' -Status 1123 -Cluster 1 } | Should -Throw
            }
        }

        Context -Name "Add-NBVirtualMachineInterface" -Fixture {
            It "Should add a basic interface" {
                $Result = Add-NBVirtualMachineInterface -Name 'Ethernet0' -Virtual_Machine 10

                Assert-VerifiableMock

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"virtual_machine":10,"name":"Ethernet0","enabled":true}'
            }

            It "Should add an interface with a MAC, MTU, and Description" {
                $Result = Add-NBVirtualMachineInterface -Name 'Ethernet0' -Virtual_Machine 10 -Mac_Address '11:22:33:44:55:66' -MTU 1500 -Description "Test description"

                Assert-VerifiableMock

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"mtu":1500,"description":"Test description","enabled":true,"virtual_machine":10,"name":"Ethernet0","mac_address":"11:22:33:44:55:66"}'
            }
        }


        Mock -CommandName "Get-NBVirtualMachine" -ModuleName NetboxPS -MockWith {
            return [pscustomobject]@{
                'Id'   = $Id
                'Name' = $Name
            }
        }

        Context -Name "Set-NBVirtualMachine" -Fixture {
            It "Should set a VM to a new name" {
                $Result = Set-NBVirtualMachine -Id 1234 -Name 'newtestname' -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName 'Get-NBVirtualMachine' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/1234/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"name":"newtestname"}'
            }

            It "Should set a VM with a new name, cluster, platform, and status" {
                $Result = Set-NBVirtualMachine -Id 1234 -Name 'newtestname' -Cluster 10 -Platform 15 -Status 'Offline' -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName 'Get-NBVirtualMachine' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/1234/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"cluster":10,"platform":15,"name":"newtestname","status":0}'
            }

            It "Should throw because of an invalid status" {
                { Set-NBVirtualMachine -Id 1234 -Status 'Fake' -Force } | Should -Throw

                Assert-VerifiableMock
                Assert-MockCalled -CommandName 'Get-NBVirtualMachine' -Times 0 -Exactly -Scope 'It'
            }
        }


        Mock -CommandName "Get-NBVirtualMachineInterface" -ModuleName NetboxPS -MockWith {
            return [pscustomobject]@{
                'Id'   = $Id
                'Name' = $Name
            }
        }

        Context -Name "Set-NBVirtualMachineInterface" -Fixture {
            It "Should set an interface to a new name" {
                $Result = Set-NBVirtualMachineInterface -Id 1234 -Name 'newtestname' -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-NBVirtualMachineInterface -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/1234/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"name":"newtestname"}'
            }

            It "Should set an interface to a new name, MTU, MAC address and description" {
                $paramSetNetboxVirtualMachineInterface = @{
                    Id          = 1234
                    Name        = 'newtestname'
                    MAC_Address = '11:22:33:44:55:66'
                    MTU         = 9000
                    Description = "Test description"
                    Force       = $true
                }

                $Result = Set-NBVirtualMachineInterface @paramSetNetboxVirtualMachineInterface

                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-NBVirtualMachineInterface -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/1234/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"mac_address":"11:22:33:44:55:66","mtu":9000,"description":"Test description","name":"newtestname"}'
            }

            It "Should set multiple interfaces to a new name" {
                $Result = Set-NBVirtualMachineInterface -Id 1234, 4321 -Name 'newtestname' -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-NBVirtualMachineInterface -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/1234/', 'https://netbox.domain.com/api/virtualization/interfaces/4321/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"name":"newtestname"}', '{"name":"newtestname"}'
            }

            It "Should set multiple interfaces to a new name from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'Id' = 4123
                    },
                    [pscustomobject]@{
                        'Id' = 4321
                    }
                ) | Set-NBVirtualMachineInterface -Name 'newtestname' -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName Get-NBVirtualMachineInterface -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/4123/', 'https://netbox.domain.com/api/virtualization/interfaces/4321/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"name":"newtestname"}', '{"name":"newtestname"}'
            }
        }

        Context -Name "Remove-NBVirtualMachine" -Fixture {
            It "Should remove a single VM" {
                $Result = Remove-NBVirtualMachine -Id 4125 -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName 'Get-NBVirtualMachine' -Times 1 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/4125/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should remove mulitple VMs" {
                $Result = Remove-NBVirtualMachine -Id 4125, 4132 -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName 'Get-NBVirtualMachine' -Times 2 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/4125/', 'https://netbox.domain.com/api/virtualization/virtual-machines/4132/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }

            It "Should remove a VM from the pipeline" {
                $Result = Get-NBVirtualMachine -Id 4125 | Remove-NBVirtualMachine -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName 'Get-NBVirtualMachine' -Times 2 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/4125/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should remove multiple VMs from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'Id' = 4125
                    },
                    [pscustomobject]@{
                        'Id' = 4132
                    }
                ) | Remove-NBVirtualMachine -Force

                Assert-VerifiableMock
                Assert-MockCalled -CommandName 'Get-NBVirtualMachine' -Times 2 -Exactly -Scope 'It'

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/4125/', 'https://netbox.domain.com/api/virtualization/virtual-machines/4132/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }
        }
    }
}










