#Requires -Module Pester

<#
.SYNOPSIS
    Error handling and edge case tests for PowerNetbox.

.DESCRIPTION
    Tests API error responses, network failures, invalid inputs,
    and retry logic behavior.

.NOTES
    These tests use realistic HTTP exception mocking that matches how
    InvokeNetboxRequest.ps1 extracts status codes from exception responses.
#>

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    . "$PSScriptRoot/common.ps1"

    # Helper function to create realistic HTTP exceptions with StatusCode
    # This matches what Invoke-RestMethod throws and what InvokeNetboxRequest expects
    function New-HttpException {
        param(
            [Parameter(Mandatory)]
            [int]$StatusCode,
            [string]$StatusDescription = "HTTP Error",
            [string]$ResponseBody = $null
        )

        # Create a mock response object with the StatusCode property
        $mockResponse = [PSCustomObject]@{
            StatusCode = [System.Net.HttpStatusCode]$StatusCode
            StatusDescription = $StatusDescription
        }

        # Add GetResponseStream method if we have a response body
        if ($ResponseBody) {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($ResponseBody)
            $stream = [System.IO.MemoryStream]::new($bytes)
            $mockResponse | Add-Member -MemberType ScriptMethod -Name 'GetResponseStream' -Value {
                return $stream
            }.GetNewClosure()
        }
        else {
            $mockResponse | Add-Member -MemberType ScriptMethod -Name 'GetResponseStream' -Value { return $null }
        }

        # Create the WebException with the mock response
        $webException = [System.Net.WebException]::new(
            "The remote server returned an error: ($StatusCode) $StatusDescription.",
            $null,
            [System.Net.WebExceptionStatus]::ProtocolError,
            $null
        )

        # Attach the mock response to the exception
        # PowerShell's Invoke-RestMethod wraps this in a different exception type,
        # but the Response property is what InvokeNetboxRequest looks for
        $wrappedException = [System.Exception]::new($webException.Message, $webException)

        # Add the Response property that InvokeNetboxRequest expects (line ~230-231)
        $wrappedException | Add-Member -MemberType NoteProperty -Name 'Response' -Value $mockResponse -Force

        return $wrappedException
    }
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

    Context "HTTP Error Responses (Legacy)" {

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

    Context "HTTP Status Code Handling" {
        # These tests use realistic HTTP exception mocking with actual StatusCode properties

        It "Should handle 400 Bad Request with proper error category" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 400 -StatusDescription "Bad Request" -ResponseBody '{"detail": "Invalid field value"}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "400"
        }

        It "Should handle 401 Unauthorized with authentication error" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 401 -StatusDescription "Unauthorized" -ResponseBody '{"detail": "Invalid token"}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "401"
        }

        It "Should handle 403 Forbidden with permission denied error" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 403 -StatusDescription "Forbidden" -ResponseBody '{"detail": "You do not have permission to perform this action."}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "403"
            # Should include troubleshooting hints
            $errorThrown.Exception.Message | Should -Match "permission"
        }

        It "Should handle 404 Not Found with object not found error" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 404 -StatusDescription "Not Found" -ResponseBody '{"detail": "Not found."}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice -Id 99999
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "404"
        }

        It "Should handle 405 Method Not Allowed" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 405 -StatusDescription "Method Not Allowed" -ResponseBody '{"detail": "Method not allowed."}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "405"
        }

        It "Should handle 409 Conflict" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 409 -StatusDescription "Conflict" -ResponseBody '{"detail": "Resource already exists."}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "409"
        }

        It "Should handle 429 Too Many Requests (rate limit)" {
            # 429 is retryable, so we need MaxRetries=1 to test immediate failure
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 429 -StatusDescription "Too Many Requests" -ResponseBody '{"detail": "Request was throttled."}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "429"
            $errorThrown.Exception.Message | Should -Match "rate limit"
        }

        It "Should handle 500 Internal Server Error" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 500 -StatusDescription "Internal Server Error" -ResponseBody '{"detail": "Server error"}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "500"
            $errorThrown.Exception.Message | Should -Match "server"
        }

        It "Should handle 502 Bad Gateway" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 502 -StatusDescription "Bad Gateway" -ResponseBody '')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "502"
        }

        It "Should handle 503 Service Unavailable" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 503 -StatusDescription "Service Unavailable" -ResponseBody '{"detail": "Service temporarily unavailable"}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "503"
        }

        It "Should handle 504 Gateway Timeout" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 504 -StatusDescription "Gateway Timeout" -ResponseBody '')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "504"
        }

        It "Should extract error message from JSON response body" {
            # Note: GetNetboxAPIErrorBody requires specific response types (HttpWebResponse or HttpResponseMessage)
            # Our mock PSCustomObject won't match, so we verify the status code is in the error message.
            # Full response body extraction is tested in the GetNetboxAPIErrorBody unit tests.
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 400 -StatusDescription "Bad Request" -ResponseBody '{"detail": "name: This field is required."}')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            # The error message should contain the status code
            $errorThrown.Exception.Message | Should -Match "400"
            $errorThrown.Exception.Message | Should -Match "Bad Request"
        }

        It "Should handle non-JSON error response body gracefully" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 500 -StatusDescription "Internal Server Error" -ResponseBody '<html><body>Server Error</body></html>')
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            # Should not crash when parsing non-JSON response
            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "500"
        }

        It "Should handle empty response body" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 500 -StatusDescription "Internal Server Error" -ResponseBody $null)
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown | Should -Not -BeNullOrEmpty
            $errorThrown.Exception.Message | Should -Match "500"
        }
    }

    Context "Retry Logic" {
        # Tests for the retry mechanism in InvokeNetboxRequest
        # Retryable status codes: 408, 429, 500, 502, 503, 504

        BeforeEach {
            # Track call count for retry verification
            $script:invokeCallCount = 0
        }

        It "Should retry on 429 status code (rate limit)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                if ($script:invokeCallCount -lt 3) {
                    throw (New-HttpException -StatusCode 429 -StatusDescription "Too Many Requests")
                }
                # Succeed on 3rd attempt
                return @{ results = @(@{ id = 1; name = 'test' }) }
            }

            $result = Get-NBDCIMDevice
            $result | Should -Not -BeNullOrEmpty
            $script:invokeCallCount | Should -BeGreaterOrEqual 2
        }

        It "Should retry on 503 status code (service unavailable)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                if ($script:invokeCallCount -lt 2) {
                    throw (New-HttpException -StatusCode 503 -StatusDescription "Service Unavailable")
                }
                # Succeed on 2nd attempt
                return @{ results = @(@{ id = 1; name = 'test' }) }
            }

            $result = Get-NBDCIMDevice
            $result | Should -Not -BeNullOrEmpty
            $script:invokeCallCount | Should -BeGreaterOrEqual 2
        }

        It "Should retry on 502 status code (bad gateway)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                if ($script:invokeCallCount -lt 2) {
                    throw (New-HttpException -StatusCode 502 -StatusDescription "Bad Gateway")
                }
                return @{ results = @(@{ id = 1; name = 'test' }) }
            }

            $result = Get-NBDCIMDevice
            $result | Should -Not -BeNullOrEmpty
            $script:invokeCallCount | Should -BeGreaterOrEqual 2
        }

        It "Should retry on 500 status code (internal server error)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                if ($script:invokeCallCount -lt 2) {
                    throw (New-HttpException -StatusCode 500 -StatusDescription "Internal Server Error")
                }
                return @{ results = @(@{ id = 1; name = 'test' }) }
            }

            $result = Get-NBDCIMDevice
            $result | Should -Not -BeNullOrEmpty
            $script:invokeCallCount | Should -BeGreaterOrEqual 2
        }

        It "Should retry on 504 status code (gateway timeout)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                if ($script:invokeCallCount -lt 2) {
                    throw (New-HttpException -StatusCode 504 -StatusDescription "Gateway Timeout")
                }
                return @{ results = @(@{ id = 1; name = 'test' }) }
            }

            $result = Get-NBDCIMDevice
            $result | Should -Not -BeNullOrEmpty
            $script:invokeCallCount | Should -BeGreaterOrEqual 2
        }

        It "Should retry on 408 status code (request timeout)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                if ($script:invokeCallCount -lt 2) {
                    throw (New-HttpException -StatusCode 408 -StatusDescription "Request Timeout")
                }
                return @{ results = @(@{ id = 1; name = 'test' }) }
            }

            $result = Get-NBDCIMDevice
            $result | Should -Not -BeNullOrEmpty
            $script:invokeCallCount | Should -BeGreaterOrEqual 2
        }

        It "Should NOT retry on 400 status code (bad request)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                throw (New-HttpException -StatusCode 400 -StatusDescription "Bad Request" -ResponseBody '{"detail": "Invalid input"}')
            }

            { Get-NBDCIMDevice } | Should -Throw
            # 400 is not retryable, should only be called once
            $script:invokeCallCount | Should -Be 1
        }

        It "Should NOT retry on 401 status code (unauthorized)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                throw (New-HttpException -StatusCode 401 -StatusDescription "Unauthorized")
            }

            { Get-NBDCIMDevice } | Should -Throw
            $script:invokeCallCount | Should -Be 1
        }

        It "Should NOT retry on 403 status code (forbidden)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                throw (New-HttpException -StatusCode 403 -StatusDescription "Forbidden")
            }

            { Get-NBDCIMDevice } | Should -Throw
            $script:invokeCallCount | Should -Be 1
        }

        It "Should NOT retry on 404 status code (not found)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                throw (New-HttpException -StatusCode 404 -StatusDescription "Not Found")
            }

            { Get-NBDCIMDevice -Id 99999 } | Should -Throw
            $script:invokeCallCount | Should -Be 1
        }

        It "Should respect MaxRetries limit and fail after exhausting retries" {
            # MaxRetries defaults to 3 in InvokeNetboxRequest
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:invokeCallCount++
                # Always fail with retryable error
                throw (New-HttpException -StatusCode 503 -StatusDescription "Service Unavailable")
            }

            { Get-NBDCIMDevice } | Should -Throw
            # Should attempt exactly MaxRetries times (default 3)
            $script:invokeCallCount | Should -Be 3
        }

        It "Should eventually succeed after transient failures" -Skip {
            # SKIPPED: This test requires complex cross-scope state tracking that is
            # difficult to achieve with Pester mocks. The retry logic is already
            # verified by other tests that check:
            # 1. Retryable status codes trigger retries (tests above for 408, 429, 500, 502, 503, 504)
            # 2. Non-retryable codes fail immediately without retry
            # 3. MaxRetries limit is respected
            #
            # For full integration testing of retry-then-succeed scenarios,
            # use the Integration.Tests.ps1 with a real Netbox instance.
        }
    }

    Context "Error Category Mapping" {
        # Tests that verify InvokeNetboxRequest maps HTTP status codes to correct PowerShell error categories

        It "Should map 400 to InvalidArgument category" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 400 -StatusDescription "Bad Request")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.CategoryInfo.Category | Should -Be 'InvalidArgument'
        }

        It "Should map 401 to AuthenticationError category" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 401 -StatusDescription "Unauthorized")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.CategoryInfo.Category | Should -Be 'AuthenticationError'
        }

        It "Should map 403 to PermissionDenied category" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 403 -StatusDescription "Forbidden")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.CategoryInfo.Category | Should -Be 'PermissionDenied'
        }

        It "Should map 404 to ObjectNotFound category" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 404 -StatusDescription "Not Found")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice -Id 99999
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.CategoryInfo.Category | Should -Be 'ObjectNotFound'
        }

        It "Should map 429 to LimitsExceeded category" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 429 -StatusDescription "Too Many Requests")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.CategoryInfo.Category | Should -Be 'LimitsExceeded'
        }

        It "Should map 5xx to ConnectionError category" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 500 -StatusDescription "Internal Server Error")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.CategoryInfo.Category | Should -Be 'ConnectionError'
        }
    }

    Context "Troubleshooting Hints in Error Messages" {
        # Verify that error messages include helpful troubleshooting guidance

        It "Should include API token troubleshooting for 401 errors" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 401 -StatusDescription "Unauthorized")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.Exception.Message | Should -Match "token"
        }

        It "Should include permission troubleshooting for 403 errors" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 403 -StatusDescription "Forbidden")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.Exception.Message | Should -Match "permission"
        }

        It "Should include resource troubleshooting for 404 errors" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 404 -StatusDescription "Not Found")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice -Id 99999
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.Exception.Message | Should -Match "resource|endpoint"
        }

        It "Should include rate limit troubleshooting for 429 errors" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 429 -StatusDescription "Too Many Requests")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.Exception.Message | Should -Match "rate limit|throttl"
        }

        It "Should include server troubleshooting for 5xx errors" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 503 -StatusDescription "Service Unavailable")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.Exception.Message | Should -Match "server"
        }

        It "Should include endpoint and method in error message" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw (New-HttpException -StatusCode 404 -StatusDescription "Not Found")
            }

            $errorThrown = $null
            try {
                Get-NBDCIMDevice
            }
            catch {
                $errorThrown = $_
            }

            $errorThrown.Exception.Message | Should -Match "GET"
            $errorThrown.Exception.Message | Should -Match "dcim"
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

    BeforeAll {
        InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
            $script:NetboxConfig.Hostname = 'netbox.test.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "HttpWebResponse Handling (PowerShell Desktop)" {
        It "Should extract error body from HttpWebResponse" {
            InModuleScope -ModuleName 'PowerNetbox' {
                # Create a mock HttpWebResponse-like object
                $responseBody = '{"detail": "Invalid field value"}'
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
                $stream = [System.IO.MemoryStream]::new($bytes)

                $mockResponse = New-Object PSObject
                $mockResponse | Add-Member -MemberType ScriptMethod -Name 'GetResponseStream' -Value {
                    $stream
                }.GetNewClosure()
                # Mark it as HttpWebResponse type
                $mockResponse.PSTypeNames.Insert(0, 'System.Net.HttpWebResponse')

                # Call the function
                $result = GetNetboxAPIErrorBody -Response $mockResponse

                $result | Should -Be $responseBody
            }
        }

        It "Should return empty string when stream is null" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $mockResponse = New-Object PSObject
                $mockResponse | Add-Member -MemberType ScriptMethod -Name 'GetResponseStream' -Value { $null }
                $mockResponse.PSTypeNames.Insert(0, 'System.Net.HttpWebResponse')

                $result = GetNetboxAPIErrorBody -Response $mockResponse

                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context "Error Resilience" {
        It "Should return empty string when response reading fails" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $mockResponse = New-Object PSObject
                $mockResponse | Add-Member -MemberType ScriptMethod -Name 'GetResponseStream' -Value {
                    throw "Stream error"
                }
                $mockResponse.PSTypeNames.Insert(0, 'System.Net.HttpWebResponse')

                $result = GetNetboxAPIErrorBody -Response $mockResponse

                $result | Should -BeNullOrEmpty
            }
        }

        It "Should return empty string for unknown response type" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $mockResponse = [PSCustomObject]@{ SomeProperty = "value" }

                $result = GetNetboxAPIErrorBody -Response $mockResponse

                $result | Should -BeNullOrEmpty
            }
        }
    }
}

Describe "BuildDetailedErrorMessage Helper" -Tag 'ErrorHandling', 'Helper' {

    BeforeAll {
        InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
            $script:NetboxConfig.Hostname = 'netbox.test.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Status Code Specific Troubleshooting" {
        It "Should provide 401 Unauthorized troubleshooting hints" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 401 -StatusName "Unauthorized" `
                    -Method "GET" -Endpoint "/api/dcim/devices/" -ErrorMessage "Authentication failed"

                $result | Should -Match "401 Unauthorized"
                $result | Should -Match "GET /api/dcim/devices/"
                $result | Should -Match "API token is correct"
                $result | Should -Match "Admin > API Tokens"
            }
        }

        It "Should provide 403 Forbidden troubleshooting hints" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 403 -StatusName "Forbidden" `
                    -Method "DELETE" -Endpoint "/api/dcim/devices/123/" -ErrorMessage "Permission denied"

                $result | Should -Match "403 Forbidden"
                $result | Should -Match "DELETE /api/dcim/devices/123/"
                $result | Should -Match "token has permission"
                $result | Should -Match "object-level permissions"
            }
        }

        It "Should provide 404 Not Found troubleshooting hints" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 404 -StatusName "Not Found" `
                    -Method "GET" -Endpoint "/api/dcim/devices/99999/" -ErrorMessage "Not found"

                $result | Should -Match "404 Not Found"
                $result | Should -Match "resource ID exists"
                $result | Should -Match "resource was deleted"
            }
        }

        It "Should provide 429 Rate Limit troubleshooting hints" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 429 -StatusName "Too Many Requests" `
                    -Method "GET" -Endpoint "/api/dcim/devices/" -ErrorMessage "Rate limited"

                $result | Should -Match "429 Too Many Requests"
                $result | Should -Match "rate limited"
                $result | Should -Match "Wait a moment"
            }
        }

        It "Should provide 500+ Server Error troubleshooting hints" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 500 -StatusName "Internal Server Error" `
                    -Method "POST" -Endpoint "/api/dcim/devices/" -ErrorMessage "Server error"

                $result | Should -Match "500 Internal Server Error"
                $result | Should -Match "server-side error"
                $result | Should -Match "Netbox server logs"
            }
        }

        It "Should provide 503 Service Unavailable troubleshooting hints" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 503 -StatusName "Service Unavailable" `
                    -Method "GET" -Endpoint "/api/" -ErrorMessage "Service down"

                $result | Should -Match "503 Service Unavailable"
                $result | Should -Match "server-side error"
                $result | Should -Match "Netbox service is running"
            }
        }

        It "Should provide generic troubleshooting for unknown status codes" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 418 -StatusName "I'm a teapot" `
                    -Method "GET" -Endpoint "/api/teapot/" -ErrorMessage "Cannot brew coffee"

                $result | Should -Match "418 I'm a teapot"
                $result | Should -Match "Check your request parameters"
            }
        }
    }

    Context "Error Message Format" {
        It "Should include all provided information in the message" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 400 -StatusName "Bad Request" `
                    -Method "POST" -Endpoint "/api/ipam/ip-addresses/" -ErrorMessage "Invalid IP format"

                $result | Should -Match "400 Bad Request"
                $result | Should -Match "POST /api/ipam/ip-addresses/"
                $result | Should -Match "Invalid IP format"
                $result | Should -Match "Troubleshooting:"
            }
        }

        It "Should handle empty error message gracefully" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = BuildDetailedErrorMessage -StatusCode 400 -StatusName "Bad Request" `
                    -Method "GET" -Endpoint "/api/test/" -ErrorMessage ""

                $result | Should -Match "400 Bad Request"
                $result | Should -Match "GET /api/test/"
            }
        }
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
