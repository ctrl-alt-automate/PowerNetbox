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
    $script:ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    $script:LiveTesting = $env:NETBOX_HOST -and $env:NETBOX_TOKEN
}

BeforeAll {
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
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

        # Determine scheme - default to http for Docker CI, https for cloud
        $scheme = $env:NETBOX_SCHEME
        if ([string]::IsNullOrEmpty($scheme)) {
            # Docker CI uses http on localhost
            if ($env:NETBOX_HOST -match 'localhost|127\.0\.0\.1') {
                $scheme = 'http'
            }
            else {
                $scheme = 'https'
            }
        }

        $connectParams = @{
            Hostname   = $env:NETBOX_HOST
            Credential = $credential
            Scheme     = $scheme
        }

        # Only skip certificate check for https
        if ($scheme -eq 'https') {
            $connectParams['SkipCertificateCheck'] = $true
        }

        Connect-NBAPI @connectParams

        # Generate unique test prefix for this run
        $script:TestRunId = [guid]::NewGuid().ToString().Substring(0, 8)
        $script:TestPrefix = "LiveTest-$($script:TestRunId)"

        # Track created resources for cleanup
        $script:CreatedResources = @{
            Sites     = [System.Collections.ArrayList]::new()
            Tenants   = [System.Collections.ArrayList]::new()
            Addresses = [System.Collections.ArrayList]::new()
            Prefixes  = [System.Collections.ArrayList]::new()
        }

        Write-Host "Test Run ID: $script:TestRunId" -ForegroundColor Cyan
    }

    AfterAll {
        Write-Host "`nCleaning up live test resources..." -ForegroundColor Yellow

        # Cleanup in reverse dependency order
        foreach ($id in $script:CreatedResources.Addresses) {
            Remove-NBIPAMAddress -Id $id -Confirm:$false -ErrorAction SilentlyContinue
        }
        foreach ($id in $script:CreatedResources.Prefixes) {
            Remove-NBIPAMPrefix -Id $id -Confirm:$false -ErrorAction SilentlyContinue
        }
        foreach ($id in $script:CreatedResources.Sites) {
            Remove-NBDCIMSite -Id $id -Confirm:$false -ErrorAction SilentlyContinue
        }
        foreach ($id in $script:CreatedResources.Tenants) {
            Remove-NBTenant -Id $id -Confirm:$false -ErrorAction SilentlyContinue
        }

        Write-Host "Cleanup complete." -ForegroundColor Green
    }

    Context "API Connectivity" {
        It "Should connect successfully" {
            Test-NBAPIConnected | Should -Be $true
        }

        It "Should retrieve Netbox version" {
            $version = Get-NBVersion
            $version | Should -Not -BeNullOrEmpty
            $version.'netbox-version' | Should -Match '^\d+\.\d+\.\d+'
            Write-Host "  Netbox version: $($version.'netbox-version')" -ForegroundColor Green
        }

        It "Should have correct hostname" {
            Get-NBHostname | Should -Be $env:NETBOX_HOST
        }
    }

    Context "DCIM Sites CRUD" {
        BeforeAll {
            $script:TestSiteName = "$($script:TestPrefix)-Site"
            $script:TestSiteSlug = $script:TestSiteName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a new site" {
            $site = New-NBDCIMSite -Name $script:TestSiteName -Slug $script:TestSiteSlug -Status 'active'

            $site | Should -Not -BeNullOrEmpty
            $site.name | Should -Be $script:TestSiteName

            $script:TestSiteId = $site.id
            [void]$script:CreatedResources.Sites.Add($site.id)

            Write-Host "  Created site: $($site.name) (ID: $($site.id))" -ForegroundColor Green
        }

        It "Should get the site by ID" {
            $site = Get-NBDCIMSite -Id $script:TestSiteId

            $site | Should -Not -BeNullOrEmpty
            $site.id | Should -Be $script:TestSiteId
        }

        It "Should update the site" {
            $site = Set-NBDCIMSite -Id $script:TestSiteId -Description "$script:TestPrefix - Updated"

            $site.description | Should -BeLike "*Updated*"
        }

        It "Should delete the site" {
            { Remove-NBDCIMSite -Id $script:TestSiteId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Sites.Remove($script:TestSiteId)
        }
    }

    Context "IPAM Address CRUD" {
        BeforeAll {
            $octet3 = Get-Random -Minimum 1 -Maximum 254
            $octet4 = Get-Random -Minimum 1 -Maximum 254
            $script:TestAddress = "10.99.$octet3.$octet4/32"
        }

        It "Should create a new IP address" {
            $ip = New-NBIPAMAddress -Address $script:TestAddress -Status 'active' -Description "$script:TestPrefix-IP"

            $ip | Should -Not -BeNullOrEmpty
            $ip.address | Should -Be $script:TestAddress

            $script:TestAddressId = $ip.id
            [void]$script:CreatedResources.Addresses.Add($ip.id)

            Write-Host "  Created IP: $($ip.address) (ID: $($ip.id))" -ForegroundColor Green
        }

        It "Should get the IP address by ID" {
            $ip = Get-NBIPAMAddress -Id $script:TestAddressId

            $ip | Should -Not -BeNullOrEmpty
            $ip.id | Should -Be $script:TestAddressId
        }

        It "Should delete the IP address" {
            { Remove-NBIPAMAddress -Id $script:TestAddressId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Addresses.Remove($script:TestAddressId)
        }
    }

    Context "IPAM Prefix CRUD" {
        BeforeAll {
            $octet2 = Get-Random -Minimum 1 -Maximum 254
            $script:TestPrefixValue = "10.$octet2.0.0/24"
        }

        It "Should create a new prefix" {
            $prefix = New-NBIPAMPrefix -Prefix $script:TestPrefixValue -Status 'active' -Description "$script:TestPrefix-Prefix"

            $prefix | Should -Not -BeNullOrEmpty
            $prefix.prefix | Should -Be $script:TestPrefixValue

            $script:TestPrefixId = $prefix.id
            [void]$script:CreatedResources.Prefixes.Add($prefix.id)

            Write-Host "  Created prefix: $($prefix.prefix) (ID: $($prefix.id))" -ForegroundColor Green
        }

        It "Should delete the prefix" {
            { Remove-NBIPAMPrefix -Id $script:TestPrefixId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Prefixes.Remove($script:TestPrefixId)
        }
    }

    Context "Tenancy Tenant CRUD" {
        BeforeAll {
            $script:TestTenantName = "$($script:TestPrefix)-Tenant"
            $script:TestTenantSlug = $script:TestTenantName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a new tenant" {
            $tenant = New-NBTenant -Name $script:TestTenantName -Slug $script:TestTenantSlug

            $tenant | Should -Not -BeNullOrEmpty
            $tenant.name | Should -Be $script:TestTenantName

            $script:TestTenantId = $tenant.id
            [void]$script:CreatedResources.Tenants.Add($tenant.id)

            Write-Host "  Created tenant: $($tenant.name) (ID: $($tenant.id))" -ForegroundColor Green
        }

        It "Should delete the tenant" {
            { Remove-NBTenant -Id $script:TestTenantId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Tenants.Remove($script:TestTenantId)
        }
    }

    Context "Pagination" {
        It "Should support -All switch" {
            { Get-NBDCIMSite -All } | Should -Not -Throw
        }

        It "Should support -Limit and -Offset" {
            { Get-NBDCIMSite -Limit 10 -Offset 0 } | Should -Not -Throw
        }
    }

    Context "Error Handling" {
        It "Should throw on non-existent ID" {
            { Get-NBDCIMSite -Id 999999999 } | Should -Throw
        }

        It "Should return empty for non-existent name" {
            $result = Get-NBDCIMSite -Name "NonExistent-$([guid]::NewGuid())"
            $result | Should -BeNullOrEmpty
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

    Context "Version Compatibility" {
        It "Should use /api/core/object-types/ endpoint (Netbox 4.x)" {
            { Get-NBObjectType -Limit 1 } | Should -Not -Throw
        }
    }
}
