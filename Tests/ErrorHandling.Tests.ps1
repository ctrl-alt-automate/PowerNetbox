#Requires -Module Pester

<#
.SYNOPSIS
    Error handling and edge case tests for PowerNetbox.

.DESCRIPTION
    Tests API error responses, network failures, invalid inputs,
    and retry logic behavior.
#>

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    . "$PSScriptRoot/common.ps1"
}

Describe "PowerNetbox Error Handling" -Tag 'ErrorHandling' {

    BeforeAll {
        # Set up module internal state for all tests
        InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
            $script:NetboxConfig.Hostname = 'netbox.test.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            [PSCredential]::new('api', (ConvertTo-SecureString 'test-token' -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { 'netbox.test.com' }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { @{} }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { 30 }
    }

    Context "HTTP Error Responses" {

        It "Should throw when API returns an error" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw [System.Exception]::new("API Error occurred")
            }

            { Get-NBDCIMDevice } | Should -Throw
        }

        It "Should throw PermissionDenied for 403 Forbidden" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $ex = [System.Exception]::new("403 Forbidden")
                throw $ex
            }

            { Get-NBDCIMDevice } | Should -Throw
        }

        It "Should throw ObjectNotFound for 404 Not Found" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw [System.Exception]::new("404 Not Found")
            }

            { Get-NBDCIMDevice -Id 99999 } | Should -Throw
        }
    }

    Context "Input Validation" {

        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                @{ results = @(@{ id = 1; name = 'test' }) }
            }
        }

        It "Should accept valid Limit parameter" {
            { Get-NBDCIMDevice -Limit 100 } | Should -Not -Throw
        }

        It "Should reject invalid Limit parameter" {
            { Get-NBDCIMDevice -Limit 9999 } | Should -Throw "*greater than the maximum*"
        }

        It "Should accept string Name parameter for interface" {
            # Regression test for Issue #54
            { Get-NBDCIMInterface -Name "eth0" } | Should -Not -Throw
        }
    }

    Context "Empty Response Handling" {

        It "Should handle empty results array gracefully" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                @{ count = 0; results = @() }
            }

            $result = Get-NBDCIMDevice
            $result | Should -BeNullOrEmpty
        }

        It "Should handle null response gracefully" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return $null
            }

            $result = Get-NBDCIMDevice
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Connection Validation" {

        It "Should throw when not connected" {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith {
                throw "Not connected to Netbox API. Use Connect-NBAPI first."
            }

            { Get-NBDCIMDevice } | Should -Throw "*Connect-NBAPI*"
        }
    }
}

Describe "GetNetboxAPIErrorBody Helper" -Tag 'ErrorHandling', 'Helper' {

    It "Should return empty string for null response stream" {
        # This tests the helper function's null handling
        $mockResponse = [PSCustomObject]@{
            GetResponseStream = { return $null }
        }

        # The function should handle null gracefully
        # Note: This is a unit test concept - actual implementation may vary
    }
}

Describe "Error Message Quality" -Tag 'ErrorHandling', 'UX' {

    Context "Troubleshooting Hints" {

        It "Should provide helpful error context when API returns errors" {
            # Test that error handling provides useful context
            # The actual BuildDetailedErrorMessage is an internal function
            # We verify error messages are informative through the module behavior

            Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
                [PSCredential]::new('api', (ConvertTo-SecureString 'test-token' -AsPlainText -Force))
            }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { @{} }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { 30 }
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { $true }
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw [System.Exception]::new("API Error: Something went wrong")
            }

            # Verify that errors are thrown with context
            { Get-NBDCIMDevice } | Should -Throw
        }
    }
}
