[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module NetboxPSv4 -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path $PSScriptRoot ".." "NetboxPSv4" "NetboxPSv4.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    $script:TestPath = $PSScriptRoot
}

Describe "IPAM tests" -Tag 'Ipam' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'NetboxPSv4' -MockWith { return $true }
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
        Mock -CommandName 'Get-NBHostname' -ModuleName 'NetboxPSv4' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'NetboxPSv4' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'NetboxPSv4' -MockWith { return @{} }

        InModuleScope -ModuleName 'NetboxPSv4' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
            $script:NetboxConfig.Choices.IPAM = (Get-Content "$TestPath/IPAMChoices.json" -ErrorAction Stop | ConvertFrom-Json)
        }
    }

    Context "Get-NBIPAMAggregate" {
        It "Should request the default number of aggregates" {
            $Result = Get-NBIPAMAggregate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBIPAMAggregate -Limit 10 -Offset 12
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=12'
        }

        It "Should request with a query" {
            $Result = Get-NBIPAMAggregate -Query '10.10.0.0'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/?q=10.10.0.0'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBIPAMAggregate -Query 'my aggregate'
            $Result.Method | Should -Be 'GET'
            # Module doesn't URL-encode spaces in query strings
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/?q=my aggregate'
        }

        It "Should request with a single ID" {
            $Result = Get-NBIPAMAggregate -Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/10/'
        }

        It "Should request with multiple IDs" {
            $Result = Get-NBIPAMAggregate -Id 10, 12, 15
            # Multiple IDs result in multiple requests (one per ID)
            $Result.Count | Should -Be 3
        }
    }

    Context "Get-NBIPAMAddress" {
        It "Should request the default number of addresses" {
            $Result = Get-NBIPAMAddress
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBIPAMAddress -Limit 10 -Offset 12
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=12'
        }

        It "Should request with a query" {
            $Result = Get-NBIPAMAddress -Query '10.10.10.10'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?q=10.10.10.10'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBIPAMAddress -Query 'my ip address'
            $Result.Method | Should -Be 'GET'
            # Module doesn't URL-encode spaces in query strings
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?q=my ip address'
        }

        It "Should request with a single ID" {
            $Result = Get-NBIPAMAddress -Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/10/'
        }

        It "Should request with multiple IDs" {
            $Result = Get-NBIPAMAddress -Id 10, 12, 15
            # Multiple IDs result in multiple requests (one per ID)
            $Result.Count | Should -Be 3
        }

        It "Should request with a family number" {
            $Result = Get-NBIPAMAddress -Family 4
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?family=4'
        }

        It "Should request with a family name" {
            $Result = Get-NBIPAMAddress -Family 'IPv4'
            $Result.Method | Should -Be 'GET'
            # Family value is passed through to API as-is
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?family=IPv4'
        }
    }

    Context "Get-NBIPAMAvailableIP" {
        It "Should request the default number of available IPs" {
            $Result = Get-NBIPAMAvailableIP -Prefix_Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/10/available-ips/'
        }

        It "Should request 10 available IPs" {
            $Result = Get-NBIPAMAvailableIP -Prefix_Id 1504 -NumberOfIPs 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/1504/available-ips/?limit=10'
        }
    }

    Context "Get-NBIPAMPrefix" {
        It "Should request the default number of prefixes" {
            $Result = Get-NBIPAMPrefix
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBIPAMPrefix -Limit 10 -Offset 12
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=12'
        }

        It "Should request with a query" {
            $Result = Get-NBIPAMPrefix -Query '10.10.10.10'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?q=10.10.10.10'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBIPAMPrefix -Query 'my ip address'
            $Result.Method | Should -Be 'GET'
            # Module doesn't URL-encode spaces in query strings
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?q=my ip address'
        }

        It "Should request with a single ID" {
            $Result = Get-NBIPAMPrefix -Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/10/'
        }

        It "Should request with multiple IDs" {
            $Result = Get-NBIPAMPrefix -Id 10, 12, 15
            # Multiple IDs result in multiple requests (one per ID)
            $Result.Count | Should -Be 3
        }

        It "Should request with VLAN vID" {
            $Result = Get-NBIPAMPrefix -VLAN_VID 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?vlan_vid=10'
        }

        It "Should request with family of 4" {
            $Result = Get-NBIPAMPrefix -Family 4
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?family=4'
        }

        It "Should throw because the mask length is too large" {
            { Get-NBIPAMPrefix -Mask_length 128 } | Should -Throw
        }

        It "Should throw because the mask length is too small" {
            { Get-NBIPAMPrefix -Mask_length -1 } | Should -Throw
        }

        It "Should not throw because the mask length is just right" {
            { Get-NBIPAMPrefix -Mask_length 24 } | Should -Not -Throw
        }

        It "Should request with mask length 24" {
            $Result = Get-NBIPAMPrefix -Mask_length 24
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?mask_length=24'
        }
    }

    Context "New-NBIPAMPrefix" {
        It "Should create a basic prefix" {
            $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24"
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It' -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'POST'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
            # Module no longer adds default status
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.prefix | Should -Be '10.0.0.0/24'
        }

        It "Should create a prefix with a status and role names" {
            $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Status 'Active' -Role 'Active'
            $Result.Method | Should -Be 'POST'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
            # Status is passed through as string (no client-side validation)
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.prefix | Should -Be '10.0.0.0/24'
            $bodyObj.status | Should -Be 'Active'
            $bodyObj.role | Should -Be 'Active'
        }

        It "Should create a prefix with a status, role name, and tenant ID" {
            $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Status 'Active' -Role 'Active' -Tenant 15
            $Result.Method | Should -Be 'POST'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.prefix | Should -Be '10.0.0.0/24'
            $bodyObj.status | Should -Be 'Active'
            $bodyObj.tenant | Should -Be 15
            $bodyObj.role | Should -Be 'Active'
        }
    }

    Context "New-NBIPAMAddress" {
        It "Should create a basic IP address" {
            $Result = New-NBIPAMAddress -Address '10.0.0.1/24'
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It' -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
            # Module no longer adds default status
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.address | Should -Be '10.0.0.1/24'
        }

        It "Should create an IP with a status and role names" {
            $Result = New-NBIPAMAddress -Address '10.0.0.1/24' -Status 'Reserved' -Role 'Anycast'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
            # Status and role are passed through as strings (no client-side validation)
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.address | Should -Be '10.0.0.1/24'
            $bodyObj.status | Should -Be 'Reserved'
            $bodyObj.role | Should -Be 'Anycast'
        }

        It "Should create an IP with a status and role values" {
            $Result = New-NBIPAMAddress -Address '10.0.1.1/24' -Status '1' -Role '10'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
            # Values are passed through as strings
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.address | Should -Be '10.0.1.1/24'
            $bodyObj.status | Should -Be '1'
            $bodyObj.role | Should -Be '10'
        }
    }

    Context "Remove-NBIPAMAddress" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMAddress" -ModuleName NetboxPSv4 -MockWith {
                return @{
                    'address' = "10.1.1.1/$Id"
                    'id'      = $id
                }
            }
        }

        It "Should remove a single IP" {
            $Result = Remove-NBIPAMAddress -Id 4109 -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope 'It' -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/'
        }

        It "Should remove a single IP from the pipeline" {
            $Result = [pscustomobject]@{ 'id' = 4110 } | Remove-NBIPAMAddress -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope 'It' -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4110/'
        }

        It "Should remove multiple IPs" {
            $Result = Remove-NBIPAMAddress -Id 4109, 4110 -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 2 -Scope 'It' -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'DELETE', 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/', 'https://netbox.domain.com/api/ipam/ip-addresses/4110/'
        }

        It "Should remove multiple IPs from the pipeline" {
            $Result = @(
                [pscustomobject]@{ 'id' = 4109 },
                [pscustomobject]@{ 'id' = 4110 }
            ) | Remove-NBIPAMAddress -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 2 -Scope 'It' -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'DELETE', 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/', 'https://netbox.domain.com/api/ipam/ip-addresses/4110/'
        }
    }

    Context "Set-NBIPAMAddress" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMAddress" -ModuleName NetboxPSv4 -MockWith {
                return @{
                    'address' = '10.1.1.1/24'
                    'id'      = $id
                }
            }
        }

        It "Should set an IP with a new status" {
            $Result = Set-NBIPAMAddress -Id 4109 -Status 2 -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope "It" -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/'
            # Status is passed as string in JSON
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.status | Should -Be '2'
        }

        It "Should set an IP from the pipeline" {
            $Result = [pscustomobject]@{ 'Id' = 4501 } | Set-NBIPAMAddress -VRF 10 -Tenant 14 -Description 'Test description' -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope "It" -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4501/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.vrf | Should -Be 10
            $bodyObj.tenant | Should -Be 14
            $bodyObj.description | Should -Be 'Test description'
        }

        It "Should set mulitple IPs to a new status" {
            $Result = Set-NBIPAMAddress -Id 4109, 4555 -Status 2 -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 2 -Scope "It" -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'PATCH', 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/', 'https://netbox.domain.com/api/ipam/ip-addresses/4555/'
            # Status is passed as string in JSON
            ($Result[0].Body | ConvertFrom-Json).status | Should -Be '2'
            ($Result[1].Body | ConvertFrom-Json).status | Should -Be '2'
        }

        It "Should set an IP with VRF, Tenant, and Description" {
            $Result = Set-NBIPAMAddress -Id 4110 -VRF 10 -Tenant 14 -Description 'Test description' -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope "It" -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4110/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.vrf | Should -Be 10
            $bodyObj.tenant | Should -Be 14
            $bodyObj.description | Should -Be 'Test description'
        }

        It "Should set multiple IPs from the pipeline" {
            $Result = @(
                [pscustomobject]@{ 'Id' = 4501 },
                [pscustomobject]@{ 'Id' = 4611 }
            ) | Set-NBIPAMAddress -Status 2 -Force
            Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 2 -Scope "It" -Exactly -ModuleName 'NetboxPSv4'
            $Result.Method | Should -Be 'PATCH', 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4501/', 'https://netbox.domain.com/api/ipam/ip-addresses/4611/'
            # Status is passed as string in JSON
            ($Result[0].Body | ConvertFrom-Json).status | Should -Be '2'
            ($Result[1].Body | ConvertFrom-Json).status | Should -Be '2'
        }
    }
}
