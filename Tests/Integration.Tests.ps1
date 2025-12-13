<#
.SYNOPSIS
    Integration tests for PowerNetbox module.

.DESCRIPTION
    These tests verify API interaction patterns and response parsing using mock responses.
    They can be run against a mock server or actual Netbox instance for full integration testing.

.NOTES
    Run with: Invoke-Pester -Path ./Tests/Integration.Tests.ps1 -Tag 'Integration'

    For live testing, set environment variables:
    $env:NETBOX_HOST = 'your-netbox-host.com'
    $env:NETBOX_TOKEN = 'your-api-token'
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeDiscovery {
    $script:ModulePath = Join-Path $PSScriptRoot ".." "PowerNetbox" "PowerNetbox.psd1"
    $script:LiveTesting = $env:NETBOX_HOST -and $env:NETBOX_TOKEN
}

BeforeAll {
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path $PSScriptRoot ".." "PowerNetbox" "PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "Integration Tests - Mock API Responses" -Tag 'Integration', 'Mock' {
    BeforeAll {
        # Mock standard Netbox API responses
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            [PSCredential]::new('api', (ConvertTo-SecureString -String "testtoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { 'netbox.test.local' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.test.local'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "DCIM Module - API Path Verification" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 1
                    results = @(
                        @{
                            id   = 1
                            name = 'test-device'
                            url  = 'https://netbox.test.local/api/dcim/devices/1/'
                        }
                    )
                }
            }
        }

        It "Get-NBDCIMDevice uses correct API path" {
            $result = Get-NBDCIMDevice -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/dcim/devices/'
            }
        }

        It "Get-NBDCIMSite uses correct API path" {
            $result = Get-NBDCIMSite -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/dcim/sites/'
            }
        }

        It "Get-NBDCIMRack uses correct API path" {
            $result = Get-NBDCIMRack -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/dcim/racks/'
            }
        }

        It "Get-NBDCIMManufacturer uses correct API path" {
            $result = Get-NBDCIMManufacturer -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/dcim/manufacturers/'
            }
        }
    }

    Context "IPAM Module - API Path Verification" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 1
                    results = @(@{ id = 1; address = '10.0.0.1/24' })
                }
            }
        }

        It "Get-NBIPAMAddress uses correct API path" {
            $result = Get-NBIPAMAddress -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/ipam/ip-addresses/'
            }
        }

        It "Get-NBIPAMPrefix uses correct API path" {
            $result = Get-NBIPAMPrefix -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/ipam/prefixes/'
            }
        }

        It "Get-NBIPAMVLAN uses correct API path" {
            $result = Get-NBIPAMVLAN -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/ipam/vlans/'
            }
        }

        It "Get-NBIPAMVRF uses correct API path" {
            $result = Get-NBIPAMVRF -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/ipam/vrfs/'
            }
        }
    }

    Context "VPN Module - API Path Verification" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 0
                    results = @()
                }
            }
        }

        It "Get-NBVPNTunnel uses correct API path" {
            $result = Get-NBVPNTunnel -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/vpn/tunnels/'
            }
        }

        It "Get-NBVPNL2VPN uses correct API path" {
            $result = Get-NBVPNL2VPN -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/vpn/l2vpns/'
            }
        }

        It "Get-NBVPNIKEPolicy uses correct API path" {
            $result = Get-NBVPNIKEPolicy -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/vpn/ike-policies/'
            }
        }

        It "Get-NBVPNIPSecProfile uses correct API path" {
            $result = Get-NBVPNIPSecProfile -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/vpn/ipsec-profiles/'
            }
        }
    }

    Context "Wireless Module - API Path Verification" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 0
                    results = @()
                }
            }
        }

        It "Get-NBWirelessLAN uses correct API path" {
            $result = Get-NBWirelessLAN -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/wireless/wireless-lans/'
            }
        }

        It "Get-NBWirelessLANGroup uses correct API path" {
            $result = Get-NBWirelessLANGroup -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/wireless/wireless-lan-groups/'
            }
        }

        It "Get-NBWirelessLink uses correct API path" {
            $result = Get-NBWirelessLink -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/wireless/wireless-links/'
            }
        }
    }

    Context "Response Parsing" {
        It "Should parse paginated response correctly" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count    = 150
                    next     = 'https://netbox.test.local/api/dcim/devices/?limit=50&offset=50'
                    previous = $null
                    results  = @(
                        @{ id = 1; name = 'device-1' }
                        @{ id = 2; name = 'device-2' }
                    )
                }
            }

            $result = Get-NBDCIMDevice -Limit 2
            # The module calls Invoke-RestMethod and processes results
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1
            # Result is returned from InvokeNetboxRequest which extracts .results
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should handle empty results" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 0
                    results = @()
                }
            }

            $result = Get-NBDCIMDevice -Name 'nonexistent'
            $result | Should -BeNullOrEmpty
        }

        It "Should handle single object response (by ID)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    id   = 42
                    name = 'specific-device'
                    url  = 'https://netbox.test.local/api/dcim/devices/42/'
                }
            }

            $result = Get-NBDCIMDevice -Id 42
            $result.id | Should -Be 42
            $result.name | Should -Be 'specific-device'
        }
    }

    Context "Error Handling" {
        It "Should handle 404 Not Found gracefully" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Net.WebException]::new("The remote server returned an error: (404) Not Found."),
                    "WebException",
                    [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
                    $null
                )
                throw $errorRecord
            }

            { Get-NBDCIMDevice -Id 99999 } | Should -Throw
        }

        It "Should handle 401 Unauthorized" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Net.WebException]::new("The remote server returned an error: (401) Unauthorized."),
                    "WebException",
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                throw $errorRecord
            }

            { Get-NBDCIMDevice } | Should -Throw
        }
    }

    Context "SupportsShouldProcess" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{ id = 1; name = 'test' }
            }
        }

        It "New-NBDCIMSite supports -WhatIf" {
            $result = New-NBDCIMSite -Name 'test-site' -Slug 'test-site' -WhatIf

            # With -WhatIf, Invoke-RestMethod should not be called
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 0
        }

        It "Set-NBDCIMSite supports -WhatIf" {
            Mock -CommandName 'Get-NBDCIMSite' -ModuleName 'PowerNetbox' -MockWith {
                return @{ id = 1; name = 'test-site' }
            }

            $result = Set-NBDCIMSite -Id 1 -Description 'Updated' -WhatIf

            # The PATCH call should not happen with -WhatIf
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Method -eq 'PATCH'
            } -Times 0
        }

        It "Remove-NBDCIMSite supports -WhatIf" {
            Mock -CommandName 'Get-NBDCIMSite' -ModuleName 'PowerNetbox' -MockWith {
                return @{ id = 1; name = 'test-site' }
            }

            $result = Remove-NBDCIMSite -Id 1 -WhatIf

            # The DELETE call should not happen with -WhatIf
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Method -eq 'DELETE'
            } -Times 0
        }
    }
}

Describe "Live Integration Tests" -Tag 'Integration', 'Live' -Skip:(-not $script:LiveTesting) {
    BeforeAll {
        $secureToken = ConvertTo-SecureString -String $env:NETBOX_TOKEN -AsPlainText -Force
        $credential = [PSCredential]::new('api', $secureToken)
        Connect-NBAPI -Hostname $env:NETBOX_HOST -Credential $credential -SkipCertificateCheck
    }

    Context "API Connectivity" {
        It "Should connect successfully" {
            Test-NBAPIConnected | Should -Be $true
        }

        It "Should retrieve Netbox version" {
            $version = Get-NBVersion
            $version | Should -Not -BeNullOrEmpty
            $version.'netbox-version' | Should -Match '^\d+\.\d+\.\d+'
        }
    }

    Context "DCIM Operations" {
        It "Should list sites" {
            $sites = Get-NBDCIMSite -Limit 5
            $sites | Should -Not -BeNullOrEmpty
        }

        It "Should list devices" {
            { Get-NBDCIMDevice -Limit 5 } | Should -Not -Throw
        }
    }

    Context "IPAM Operations" {
        It "Should list prefixes" {
            { Get-NBIPAMPrefix -Limit 5 } | Should -Not -Throw
        }

        It "Should list IP addresses" {
            { Get-NBIPAMAddress -Limit 5 } | Should -Not -Throw
        }
    }

    Context "VPN Operations (Netbox 4.x)" {
        It "Should query VPN tunnels without error" {
            { Get-NBVPNTunnel -Limit 1 } | Should -Not -Throw
        }

        It "Should query L2VPNs without error" {
            { Get-NBVPNL2VPN -Limit 1 } | Should -Not -Throw
        }
    }

    Context "Wireless Operations (Netbox 4.x)" {
        It "Should query wireless LANs without error" {
            { Get-NBWirelessLAN -Limit 1 } | Should -Not -Throw
        }

        It "Should query wireless links without error" {
            { Get-NBWirelessLink -Limit 1 } | Should -Not -Throw
        }
    }
}
