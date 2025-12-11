
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

Describe "DCIM Interfaces Tests" -Tag 'DCIM', 'Interfaces' {
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
        $script:NetboxConfig.Choices.DCIM = (Get-Content "$PSScriptRoot/DCIMChoices.json" -ErrorAction Stop | ConvertFrom-Json)

        Context "Get-NBDCIMInterface" {
            It "Should request the default number of interfaces" {
                $Result = Get-NBDCIMInterface

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a limit and offset" {
                $Result = Get-NBDCIMInterface -Limit 10 -Offset 100

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/?offset=100&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with enabled" {
                $Result = Get-NBDCIMInterface -Enabled $true

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/?enabled=True'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a form factor name" {
                $Result = Get-NBDCIMInterface -Form_Factor '10GBASE-T (10GE)'

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/?form_factor=1150'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should throw for an invalid form factor" {
                {
                    Get-NBDCIMInterface -Form_Factor 'Fake'
                } | Should -Throw
            }

            It "Should request devices that are mgmt only" {
                $Result = Get-NBDCIMInterface -MGMT_Only $True

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/?mgmt_only=True'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request an interface from the pipeline" {
                $Result = [pscustomobject]@{
                    'Id' = 1234
                } | Get-NBDCIMInterface

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/1234/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }
        }

        Context "New-NBDCIMInterface" {
            It "Should add a basic interface to a device" {
                $Result = New-NBDCIMInterface -Device 111 -Name "TestInterface"

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"name":"TestInterface","device":111}'
            }

            It "Should add an interface to a device with lots of properties" {
                $paramAddNetboxDCIMInterface = @{
                    Device      = 123
                    Name        = "TestInterface"
                    Form_Factor = '10GBASE-T (10GE)'
                    MTU         = 9000
                    MGMT_Only   = $true
                    Description = 'Test Description'
                    Mode        = 'Access'
                }

                $Result = New-NBDCIMInterface @paramAddNetboxDCIMInterface

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"mtu":9000,"mgmt_only":true,"description":"Test Description","mode":100,"name":"TestInterface","device":123,"form_factor":1150}'
            }

            It "Should add an interface with multiple tagged VLANs" {
                $Result = New-NBDCIMInterface -Device 444 -Name "TestInterface" -Mode 'Tagged' -Tagged_VLANs 1, 2, 3, 4

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"mode":200,"name":"TestInterface","device":444,"tagged_vlans":[1,2,3,4]}'
            }

            It "Should throw for invalid mode" {
                {
                    New-NBDCIMInterface -Device 321 -Name "Test123" -Mode 'Fake'
                } | Should -Throw
            }

            It "Should throw for out of range VLAN" {
                {
                    New-NBDCIMInterface -Device 321 -Name "Test123" -Untagged_VLAN 4100
                } | Should -Throw
            }
        }


        Mock -CommandName "Get-NBDCIMInterface" -ModuleName "NetboxPSv4" -MockWith {
            return [pscustomobject]@{
                'Id' = $Id
            }
        }

        Context "Set-NBDCIMInterface" {
            It "Should set an interface to a new name" {
                $Result = Set-NBDCIMInterface -Id 123 -Name "TestInterface"

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterface' -Times 1 -Scope 'It' -Exactly
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/123/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"name":"TestInterface"}'
            }

            It "Should set multiple interfaces to a new name" {
                $Result = Set-NBDCIMInterface -Id 456, 789 -Name "TestInterface"

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterface' -Times 2 -Scope 'It' -Exactly
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/456/', 'https://netbox.domain.com/api/dcim/interfaces/789/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"name":"TestInterface"}', '{"name":"TestInterface"}'
            }

            It "Should set multiple interfaces to a new name from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'Id' = 1234
                    },
                    [pscustomobject]@{
                        'Id' = 4231
                    }
                ) | Set-NBDCIMInterface -Name "TestInterface"

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterface' -Times 2 -Scope 'It' -Exactly
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/1234/', 'https://netbox.domain.com/api/dcim/interfaces/4231/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"name":"TestInterface"}', '{"name":"TestInterface"}'
            }

            It "Should throw for invalid form factor" {
                {
                    Set-NBDCIMInterface -Id 1234 -Form_Factor 'fake'
                } | Should -Throw
            }
        }

        Context "Remove-NBDCIMInterface" {
            It "Should remove an interface" {
                $Result = Remove-NBDCIMInterface -Id 10 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterface' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should remove multiple interfaces" {
                $Result = Remove-NBDCIMInterface -Id 10, 12 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterface' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/10/', 'https://netbox.domain.com/api/dcim/interfaces/12/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }

            It "Should remove an interface from the pipeline" {
                $Result = Get-NBDCIMInterface -Id 20 | Remove-NBDCIMInterface -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterface' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/20/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should remove mulitple interfaces from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'Id' = 30
                    },
                    [pscustomobject]@{
                        'Id' = 40
                    }
                ) | Remove-NBDCIMInterface -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterface' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/30/', 'https://netbox.domain.com/api/dcim/interfaces/40/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }
        }


        Context "Get-NBDCIMInterfaceConnection" {
            It "Should request the default number of interface connections" {
                $Result = Get-NBDCIMInterfaceConnection

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a limit and offset" {
                $Result = Get-NBDCIMInterfaceConnection -Limit 10 -Offset 100

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/?offset=100&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request connected interfaces" {
                $Result = Get-NBDCIMInterfaceConnection -Connection_Status 'Connected'

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/?connection_status=True'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should throw for an invalid connection status" {
                {
                    Get-NBDCIMInterfaceConnection -Connection_Status 'Fake'
                } | Should -Throw
            }
        }

        Context "New-NBDCIMInterfaceConnection" {
            It "Should add a new interface connection" {
                $Result = New-NBDCIMInterfaceConnection -Interface_A 21 -Interface_B 22

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"interface_b":22,"interface_a":21}'
            }

            It "Should throw because of an invalid connection status" {
                {
                    New-NBDCIMInterfaceConnection -Interface_A 21 -Interface_B 22 -Connection_Status 'fake'
                } | Should -Throw
            }
        }


        Mock -CommandName "Get-NBDCIMInterfaceConnection" -ModuleName 'NetboxPSv4' -MockWith {
            [pscustomobject]@{
                'Id' = $Id
            }
        }

        Context "Set-NBDCIMInterfaceConnection" {
            It "Should set an interface connection" {
                $Result = Set-NBDCIMInterfaceConnection -Id 123 -Interface_B 2 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/123/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"interface_b":2}'
            }

            It "Should set multiple interface connections to a new status" {
                $Result = Set-NBDCIMInterfaceConnection -Id 456, 789 -Connection_Status 'Planned' -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/456/', 'https://netbox.domain.com/api/dcim/interface-connections/789/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"connection_status":false}', '{"connection_status":false}'
            }

            It "Should set an interface connection from the pipeline" {
                $Result = [pscustomobject]@{
                    'id' = 3
                } | Set-NBDCIMInterfaceConnection -Connection_Status 'Planned' -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/3/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"connection_status":false}'
            }

            It "Should set multiple interface connections from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'id' = 456
                    },
                    [pscustomobject]@{
                        'id' = 789
                    }
                ) | Set-NBDCIMInterfaceConnection -Connection_Status 'Planned' -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/456/', 'https://netbox.domain.com/api/dcim/interface-connections/789/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"connection_status":false}', '{"connection_status":false}'
            }

            It "Should throw trying to set multiple connections to the same interface" {
                {
                    Set-NBDCIMInterfaceConnection -Id 456, 789 -Interface_B 22 -Force
                } | Should -Throw -ExpectedMessage "Cannot set multiple connections to the same interface"
            }
        }

        Context "Remove-NBDCIMInterfaceConnection" {
            It "Should remove an interface connection" {
                $Result = Remove-NBDCIMInterfaceConnection -Id 10 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterfaceConnection' -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should remove multiple interface connections" {
                $Result = Remove-NBDCIMInterfaceConnection -Id 10, 12 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterfaceConnection' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/10/', 'https://netbox.domain.com/api/dcim/interface-connections/12/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }

            It "Should remove an interface connection from the pipeline" {
                $Result = Get-NBDCIMInterfaceConnection -Id 20 | Remove-NBDCIMInterfaceConnection -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterfaceConnection' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/20/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should remove mulitple interface connections from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'Id' = 30
                    },
                    [pscustomobject]@{
                        'Id' = 40
                    }
                ) | Remove-NBDCIMInterfaceConnection -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName 'Get-NBDCIMInterfaceConnection' -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/30/', 'https://netbox.domain.com/api/dcim/interface-connections/40/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }
        }
    }
}

















