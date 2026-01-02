#Requires -Modules Pester

<#
.SYNOPSIS
    Unit tests for Invoke-NBGraphQL function.

.DESCRIPTION
    Tests GraphQL query execution, error handling, variables support,
    ResultPath extraction, and pipeline functionality.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "Invoke-NBGraphQL" -Tag 'GraphQL', 'Setup' {

    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig = @{
                Connected     = $true
                Hostname      = 'netbox.domain.com'
                HostScheme    = 'https'
                HostPort      = 443
                ParsedVersion = [version]'4.4.9'
            }
        }
    }

    Context "Parameter Validation" {

        BeforeAll {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{ data = @{ test = 'value' } }
            }
        }

        It "Should require Query parameter" {
            { Invoke-NBGraphQL -Query $null } | Should -Throw
        }

        It "Should not accept empty Query" {
            { Invoke-NBGraphQL -Query '' } | Should -Throw
        }

        It "Should accept Query as positional parameter" {
            { Invoke-NBGraphQL '{ site_list { id } }' } | Should -Not -Throw
        }

        It "Should accept Variables as hashtable" {
            { Invoke-NBGraphQL -Query '{ test }' -Variables @{ limit = 10 } } | Should -Not -Throw
        }

        It "Should not accept empty OperationName" {
            { Invoke-NBGraphQL -Query '{ test }' -OperationName '' } | Should -Throw
        }

        It "Should not accept empty ResultPath" {
            { Invoke-NBGraphQL -Query '{ test }' -ResultPath '' } | Should -Throw
        }

        It "Should accept Timeout parameter" {
            { Invoke-NBGraphQL -Query '{ test }' -Timeout 60 } | Should -Not -Throw
        }
    }

    Context "Timeout Support" {

        It "Should pass Timeout to InvokeNetboxRequest when specified" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{ data = @{ test = 'value' } }
            } -ParameterFilter { $Timeout -eq 120 }

            Invoke-NBGraphQL -Query '{ test }' -Timeout 120

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1 -ParameterFilter { $Timeout -eq 120 }
        }

        It "Should not pass Timeout when not specified" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{ data = @{ test = 'value' } }
            } -ParameterFilter { -not $PSBoundParameters.ContainsKey('Timeout') }

            Invoke-NBGraphQL -Query '{ test }'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1
        }
    }

    Context "Basic Query Execution" {

        It "Should return data property by default" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data = @{
                        device_list = @(
                            @{ id = 1; name = 'device1' },
                            @{ id = 2; name = 'device2' }
                        )
                    }
                }
            }

            $result = Invoke-NBGraphQL -Query '{ device_list { id name } }'

            $result | Should -Not -BeNullOrEmpty
            $result.device_list | Should -HaveCount 2
        }

        It "Should call InvokeNetboxRequest with POST method" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($URI, $Method, $Body, $Raw)
                $Method | Should -Be 'POST'
                return @{ data = @{} }
            }

            Invoke-NBGraphQL -Query '{ site_list { id } }'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1
        }

        It "Should include query in request body" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($URI, $Method, $Body, $Raw)
                $Body.query | Should -Be '{ test_query { id } }'
                return @{ data = @{} }
            }

            Invoke-NBGraphQL -Query '{ test_query { id } }'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1
        }
    }

    Context "Variables Support" {

        It "Should include variables in request body" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($URI, $Method, $Body, $Raw)
                $Body.variables | Should -Not -BeNullOrEmpty
                $Body.variables.limit | Should -Be 10
                $Body.variables.status | Should -Be 'STATUS_ACTIVE'
                return @{ data = @{} }
            }

            Invoke-NBGraphQL -Query 'query ($limit: Int!) { device_list { id } }' `
                -Variables @{ limit = 10; status = 'STATUS_ACTIVE' }

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1
        }

        It "Should not include variables when not provided" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($URI, $Method, $Body, $Raw)
                $Body.ContainsKey('variables') | Should -BeFalse
                return @{ data = @{} }
            }

            Invoke-NBGraphQL -Query '{ site_list { id } }'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1
        }
    }

    Context "OperationName Support" {

        It "Should include operationName when provided" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($URI, $Method, $Body, $Raw)
                $Body.operationName | Should -Be 'GetDevices'
                return @{ data = @{} }
            }

            Invoke-NBGraphQL -Query 'query GetDevices { device_list { id } }' -OperationName 'GetDevices'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1
        }

        It "Should not include operationName when not provided" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($URI, $Method, $Body, $Raw)
                $Body.ContainsKey('operationName') | Should -BeFalse
                return @{ data = @{} }
            }

            Invoke-NBGraphQL -Query '{ site_list { id } }'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1
        }
    }

    Context "ResultPath Extraction" {

        BeforeAll {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data = @{
                        device_list = @(
                            @{ id = 1; name = 'device1' },
                            @{ id = 2; name = 'device2' }
                        )
                    }
                }
            }
        }

        It "Should extract single-level path" {
            $result = Invoke-NBGraphQL -Query '{ device_list { id } }' -ResultPath 'device_list'

            $result | Should -HaveCount 2
            $result[0].id | Should -Be 1
        }

        It "Should extract multi-level path" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data = @{
                        nested = @{
                            deep = @{
                                value = 'found'
                            }
                        }
                    }
                }
            }

            $result = Invoke-NBGraphQL -Query '{ test }' -ResultPath 'nested.deep.value'

            $result | Should -Be 'found'
        }

        It "Should return null for non-existent path" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data = @{
                        something = 'else'
                    }
                }
            }

            $result = Invoke-NBGraphQL -Query '{ test }' -ResultPath 'nonexistent.path'

            $result | Should -BeNullOrEmpty
        }
    }

    Context "Raw Response" {

        It "Should return complete response with -Raw" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data   = @{ site_list = @() }
                    errors = $null
                }
            }

            $result = Invoke-NBGraphQL -Query '{ site_list { id } }' -Raw

            $result.data | Should -Not -BeNullOrEmpty
        }

        It "Should include errors in raw response" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data   = $null
                    errors = @(
                        @{ message = "Test error" }
                    )
                }
            }

            $result = Invoke-NBGraphQL -Query '{ invalid }' -Raw

            $result.errors | Should -Not -BeNullOrEmpty
            $result.errors[0].message | Should -Be "Test error"
        }
    }

    Context "Error Handling" {

        It "Should throw on GraphQL errors without -Raw" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data   = $null
                    errors = @(
                        @{ message = "Field 'invalid' not found" }
                    )
                }
            }

            { Invoke-NBGraphQL -Query '{ invalid }' } | Should -Throw "*GraphQL query failed*"
        }

        It "Should not throw on GraphQL errors with -Raw" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data   = $null
                    errors = @(
                        @{ message = "Test error" }
                    )
                }
            }

            { Invoke-NBGraphQL -Query '{ invalid }' -Raw } | Should -Not -Throw
        }

        It "Should combine multiple error messages" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data   = $null
                    errors = @(
                        @{ message = "Error 1" },
                        @{ message = "Error 2" }
                    )
                }
            }

            { Invoke-NBGraphQL -Query '{ invalid }' } | Should -Throw "*Error 1*Error 2*"
        }

        It "Should warn about 4.5 ID filter syntax" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data   = $null
                    errors = @(
                        @{ message = "Expected value of type 'IDFilterLookup', found 1" }
                    )
                }
            }

            $warnings = $null
            try {
                Invoke-NBGraphQL -Query '{ device_list(filters: { id: 1 }) { id } }' -WarningVariable warnings 3>&1 | Out-Null
            }
            catch {
                # Expected to throw
            }

            $warnings | Should -Match '4\.5\+'
        }

        It "Should warn about 4.5 enum filter syntax" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data   = $null
                    errors = @(
                        @{ message = "Expected value of type 'DeviceStatusEnumBaseFilterLookup'" }
                    )
                }
            }

            $warnings = $null
            try {
                Invoke-NBGraphQL -Query '{ test }' -WarningVariable warnings 3>&1 | Out-Null
            }
            catch {
                # Expected to throw
            }

            # The warning pattern for enum filters
            $warnings | Should -Match 'enum'
        }
    }

    Context "Pipeline Support" {

        BeforeAll {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($URI, $Method, $Body, $Raw)
                return @{
                    data = @{
                        result = $Body.query
                    }
                }
            }
        }

        It "Should accept query from pipeline" {
            $result = '{ site_list { id } }' | Invoke-NBGraphQL -ResultPath 'result'

            $result | Should -Be '{ site_list { id } }'
        }

        It "Should process multiple queries from pipeline" {
            $queries = @(
                '{ query1 }',
                '{ query2 }',
                '{ query3 }'
            )

            $results = $queries | Invoke-NBGraphQL -ResultPath 'result'

            $results | Should -HaveCount 3
        }
    }

    Context "Connection Check" {

        It "Should check connection before executing" {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith {
                throw "Not connected to a Netbox API! Please run 'Connect-NBAPI'"
            }

            { Invoke-NBGraphQL -Query '{ test }' } | Should -Throw "*Not connected*"
        }
    }

    Context "Version Warning" {

        BeforeAll {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{ data = @{} }
            }
        }

        It "Should warn when Netbox version is below 4.3" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.2.0'
            }

            $warnings = $null
            Invoke-NBGraphQL -Query '{ test }' -WarningVariable warnings 3>&1 | Out-Null

            $warnings | Should -Match '4\.3\+'

            # Reset version
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }
        }

        It "Should not warn when Netbox version is 4.3+" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.3.0'
            }

            $warnings = $null
            Invoke-NBGraphQL -Query '{ test }' -WarningVariable warnings 3>&1 | Out-Null

            $warnings | Where-Object { $_ -match '4\.3\+' } | Should -BeNullOrEmpty

            # Reset version
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }
        }
    }

    Context "URI Construction" {

        It "Should use /graphql/ endpoint (not /api/graphql/)" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($URI)
                # GraphQL endpoint is /graphql/, NOT /api/graphql/
                $URI.Path | Should -Be '/graphql/'
                return @{ data = @{} }
            }

            Invoke-NBGraphQL -Query '{ test }'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1
        }
    }
}

Describe "Invoke-NBGraphQL Integration Scenarios" -Tag 'GraphQL', 'Integration' {

    BeforeAll {
        Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

        $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
        if (Test-Path $ModulePath) {
            Import-Module $ModulePath -ErrorAction Stop
        }

        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig = @{
                Connected     = $true
                Hostname      = 'netbox.domain.com'
                HostScheme    = 'https'
                HostPort      = 443
                ParsedVersion = [version]'4.4.9'
            }
        }
    }

    Context "Real-world Query Patterns" {

        It "Should handle device query with nested fields" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                # Use PSCustomObject for proper property access
                return [PSCustomObject]@{
                    data = [PSCustomObject]@{
                        device_list = @(
                            [PSCustomObject]@{
                                id          = 1
                                name        = 'switch-01'
                                site        = [PSCustomObject]@{ name = 'Amsterdam' }
                                primary_ip4 = [PSCustomObject]@{ address = '10.0.0.1/24' }
                            }
                        )
                    }
                }
            }

            $result = Invoke-NBGraphQL -Query @'
{
    device_list(filters: { role: { name: { exact: "switch" } } }) {
        id
        name
        site { name }
        primary_ip4 { address }
    }
}
'@ -ResultPath 'device_list'

            $result[0].name | Should -Be 'switch-01'
            $result[0].site.name | Should -Be 'Amsterdam'
            $result[0].primary_ip4.address | Should -Be '10.0.0.1/24'
        }

        It "Should handle pagination query" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data = @{
                        device_list = @(
                            @{ id = 11 },
                            @{ id = 12 },
                            @{ id = 13 },
                            @{ id = 14 },
                            @{ id = 15 }
                        )
                    }
                }
            }

            $result = Invoke-NBGraphQL -Query '{ device_list(pagination: { limit: 5, offset: 10 }) { id } }' `
                -ResultPath 'device_list'

            $result | Should -HaveCount 5
            $result[0].id | Should -Be 11
        }

        It "Should handle introspection query" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data = @{
                        __schema = @{
                            types = @(
                                @{ name = 'DeviceType'; kind = 'OBJECT' },
                                @{ name = 'SiteType'; kind = 'OBJECT' }
                            )
                        }
                    }
                }
            }

            $result = Invoke-NBGraphQL -Query '{ __schema { types { name kind } } }' `
                -ResultPath '__schema.types'

            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'DeviceType'
        }

        It "Should handle empty results" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data = @{
                        device_list = @()
                    }
                }
            }

            $result = Invoke-NBGraphQL -Query '{ device_list { id } }' -ResultPath 'device_list'

            $result | Should -HaveCount 0
        }

        It "Should handle null nested data" {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    data = @{
                        device = @{
                            id          = 1
                            primary_ip4 = $null
                        }
                    }
                }
            }

            $result = Invoke-NBGraphQL -Query '{ device(id: 1) { id primary_ip4 { address } } }' `
                -ResultPath 'device'

            $result.id | Should -Be 1
            $result.primary_ip4 | Should -BeNullOrEmpty
        }
    }
}
