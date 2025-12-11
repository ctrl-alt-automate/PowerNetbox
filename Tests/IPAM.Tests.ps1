
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


Describe "IPAM tests" -Tag 'Ipam' {
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
        $script:NetboxConfig.Choices.IPAM = (Get-Content "$PSScriptRoot/IPAMChoices.json" -ErrorAction Stop | ConvertFrom-Json)

        Context "Get-NBIPAMAggregate" {
            It "Should request the default number of aggregates" {
                $Result = Get-NBIPAMAggregate

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with limit and offset" {
                $Result = Get-NBIPAMAggregate -Limit 10 -Offset 12

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/?offset=12&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with a query" {
                $Result = Get-NBIPAMAggregate -Query '10.10.0.0'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/?q=10.10.0.0'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with an escaped query" {
                $Result = Get-NBIPAMAggregate -Query 'my aggregate'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/?q=my+aggregate'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with a single ID" {
                $Result = Get-NBIPAMAggregate -Id 10

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with multiple IDs" {
                $Result = Get-NBIPAMAggregate -Id 10, 12, 15

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/?id__in=10,12,15'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }
        }

        Context "Get-NBIPAMAddress" {
            It "Should request the default number of addresses" {
                $Result = Get-NBIPAMAddress

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with limit and offset" {
                $Result = Get-NBIPAMAddress -Limit 10 -Offset 12

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?offset=12&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with a query" {
                $Result = Get-NBIPAMAddress -Query '10.10.10.10'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?q=10.10.10.10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with an escaped query" {
                $Result = Get-NBIPAMAddress -Query 'my ip address'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?q=my+ip+address'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with a single ID" {
                $Result = Get-NBIPAMAddress -Id 10

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with multiple IDs" {
                $Result = Get-NBIPAMAddress -Id 10, 12, 15

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?id__in=10,12,15'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with a family number" {
                $Result = Get-NBIPAMAddress -Family 4

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?family=4'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }

            It "Should request with a family name" {
                $Result = Get-NBIPAMAddress -Family 'IPv4'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?family=4'
                $Result.Headers.Keys.Count | Should -BeExactly 1
            }
        }

        Context "Get-NBIPAMAvailableIP" {
            It "Should request the default number of available IPs" {
                $Result = Get-NBIPAMAvailableIP -Prefix_Id 10

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/10/available-ips/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request 10 available IPs" {
                $Result = Get-NBIPAMAvailableIP -Prefix_Id 1504 -NumberOfIPs 10

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/1504/available-ips/?limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }
        }

        Context "Get-NBIPAMPrefix" {
            It "Should request the default number of prefixes" {
                $Result = Get-NBIPAMPrefix

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with limit and offset" {
                $Result = Get-NBIPAMPrefix -Limit 10 -Offset 12

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?offset=12&limit=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with a query" {
                $Result = Get-NBIPAMPrefix -Query '10.10.10.10'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?q=10.10.10.10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with an escaped query" {
                $Result = Get-NBIPAMPrefix -Query 'my ip address'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?q=my+ip+address'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with a single ID" {
                $Result = Get-NBIPAMPrefix -Id 10

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/10/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with multiple IDs" {
                $Result = Get-NBIPAMPrefix -Id 10, 12, 15

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?id__in=10,12,15'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with VLAN vID" {
                $Result = Get-NBIPAMPrefix -VLAN_VID 10

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?vlan_vid=10'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should request with family of 4" {
                $Result = Get-NBIPAMPrefix -Family 4

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?family=4'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }

            It "Should throw because the mask length is too large" {
                {
                    Get-NBIPAMPrefix -Mask_length 128
                } | Should -Throw
            }

            It "Should throw because the mask length is too small" {
                {
                    Get-NBIPAMPrefix -Mask_length -1
                } | Should -Throw
            }

            It "Should not throw because the mask length is just right" {
                {
                    Get-NBIPAMPrefix -Mask_length 24
                } | Should -Not -Throw
            }

            It "Should request with mask length 24" {
                $Result = Get-NBIPAMPrefix -Mask_length 24

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?mask_length=24'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Headers.Authorization | Should -Be "Token faketoken"
            }
        }

        Context "New-NBIPAMPrefix" {
            It "Should create a basic prefix" {
                $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24"

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'POST'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"prefix":"10.0.0.0/24","status":1}'
            }

            It "Should create a prefix with a status and role names" {
                $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Status 'Active' -Role 'Active'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'POST'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"prefix":"10.0.0.0/24","status":1,"role":"Active"}'
            }

            It "Should create a prefix with a status, role name, and tenant ID" {
                $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Status 'Active' -Role 'Active' -Tenant 15

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'POST'
                $Result.URI | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"prefix":"10.0.0.0/24","status":1,"tenant":15,"role":"Active"}'
            }
        }

        Context "New-NBIPAMAddress" {
            It "Should create a basic IP address" {
                $Result = New-NBIPAMAddress -Address '10.0.0.1/24'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"status":1,"address":"10.0.0.1/24"}'
            }

            It "Should create an IP with a status and role names" {
                $Result = New-NBIPAMAddress -Address '10.0.0.1/24' -Status 'Reserved' -Role 'Anycast'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"status":2,"address":"10.0.0.1/24","role":30}'
            }

            It "Should create an IP with a status and role values" {
                $Result = New-NBIPAMAddress -Address '10.0.1.1/24' -Status '1' -Role '10'

                Should -InvokeVerifiable

                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"status":1,"address":"10.0.1.1/24","role":10}'
            }
        }

        Context "Remove-NBIPAMAddress" {
            Mock -CommandName "Get-NBIPAMAddress" -ModuleName NetboxPSv4 -MockWith {
                return @{
                    'address' = "10.1.1.1/$Id"
                    'id'      = $id
                }
            }

            It "Should remove a single IP" {
                $Result = Remove-NBIPAMAddress -Id 4109 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be $null
            }

            It "Should remove a single IP from the pipeline" {
                $Result = [pscustomobject]@{
                    'id' = 4110
                } | Remove-NBIPAMAddress -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4110/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be $null
            }

            It "Should remove multiple IPs" {
                $Result = Remove-NBIPAMAddress -Id 4109, 4110 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/', 'https://netbox.domain.com/api/ipam/ip-addresses/4110/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }

            It "Should remove multiple IPs from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'id' = 4109
                    },
                    [pscustomobject]@{
                        'id' = 4110
                    }
                ) | Remove-NBIPAMAddress -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 2 -Scope 'It' -Exactly

                $Result.Method | Should -Be 'DELETE', 'DELETE'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/', 'https://netbox.domain.com/api/ipam/ip-addresses/4110/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
            }
        }

        Context "Set-NBIPAMAddress" {
            Mock -CommandName "Get-NBIPAMAddress" -ModuleName NetboxPSv4 -MockWith {
                return @{
                    'address' = '10.1.1.1/24'
                    'id'      = $id
                }
            }

            It "Should set an IP with a new status" {
                $Result = Set-NBIPAMAddress -Id 4109 -Status 2 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope "It" -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"status":2}'
            }

            It "Should set an IP from the pipeline" {
                $Result = [pscustomobject]@{
                    'Id' = 4501
                } | Set-NBIPAMAddress -VRF 10 -Tenant 14 -Description 'Test description' -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope "It" -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4501/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"vrf":10,"description":"Test description","tenant":14}'
            }

            It "Should set mulitple IPs to a new status" {
                $Result = Set-NBIPAMAddress -Id 4109, 4555 -Status 2 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 2 -Scope "It" -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/', 'https://netbox.domain.com/api/ipam/ip-addresses/4555/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"status":2}', '{"status":2}'
            }

            It "Should set an IP with VRF, Tenant, and Description" {
                $Result = Set-NBIPAMAddress -Id 4110 -VRF 10 -Tenant 14 -Description 'Test description' -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 1 -Scope "It" -Exactly

                $Result.Method | Should -Be 'PATCH'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4110/'
                $Result.Headers.Keys.Count | Should -BeExactly 1
                $Result.Body | Should -Be '{"vrf":10,"description":"Test description","tenant":14}'
            }

            It "Should set multiple IPs from the pipeline" {
                $Result = @(
                    [pscustomobject]@{
                        'Id' = 4501
                    },
                    [pscustomobject]@{
                        'Id' = 4611
                    }
                ) | Set-NBIPAMAddress -Status 2 -Force

                Should -InvokeVerifiable
                Should -Invoke -CommandName "Get-NBIPAMAddress" -Times 2 -Scope "It" -Exactly

                $Result.Method | Should -Be 'PATCH', 'PATCH'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4501/', 'https://netbox.domain.com/api/ipam/ip-addresses/4611/'
                $Result.Headers.Keys.Count | Should -BeExactly 2
                $Result.Body | Should -Be '{"status":2}', '{"status":2}'
            }
        }
    }
}










