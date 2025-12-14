function InvokeNetboxRequest {
    <#
    .SYNOPSIS
        Invokes a REST API request to Netbox.

    .DESCRIPTION
        Core function for all Netbox API communication. Handles authentication,
        retry logic for transient failures, and comprehensive error handling.
        Cross-platform compatible (Windows, Linux, macOS).

        Supports automatic pagination when -All is specified for GET requests.

    .PARAMETER URI
        The URI builder object containing the API endpoint.

    .PARAMETER Headers
        Additional headers to include in the request.

    .PARAMETER Body
        The request body for POST/PATCH/PUT requests.

    .PARAMETER Timeout
        Request timeout in seconds. Defaults to module timeout setting.

    .PARAMETER Method
        HTTP method (GET, POST, PATCH, PUT, DELETE, OPTIONS).

    .PARAMETER Raw
        Return the raw API response instead of just the results array.

    .PARAMETER All
        Automatically fetch all pages of results for GET requests.
        Uses the 'next' field in API response to paginate.

    .PARAMETER PageSize
        Number of items per page when using -All. Default: 100.
        Range: 1-1000.

    .PARAMETER MaxRetries
        Maximum number of retry attempts for transient failures. Default: 3.

    .PARAMETER RetryDelayMs
        Initial delay between retries in milliseconds. Uses exponential backoff. Default: 1000.

    .OUTPUTS
        [PSCustomObject] The API response or results array.

    .EXAMPLE
        $result = InvokeNetboxRequest -URI $uri -Method GET

    .EXAMPLE
        $result = InvokeNetboxRequest -URI $uri -Method GET -All
        Fetches all pages of results automatically.

    .EXAMPLE
        $result = InvokeNetboxRequest -URI $uri -Method POST -Body $data -MaxRetries 5
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [System.UriBuilder]$URI,

        [Hashtable]$Headers = @{},

        [pscustomobject]$Body = $null,

        [ValidateRange(1, 65535)]
        [uint16]$Timeout = (Get-NBTimeout),

        [ValidateSet('GET', 'PATCH', 'PUT', 'POST', 'DELETE', 'OPTIONS', IgnoreCase = $true)]
        [string]$Method = 'GET',

        [switch]$Raw,

        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3,

        [ValidateRange(100, 30000)]
        [int]$RetryDelayMs = 1000
    )

    # Handle automatic pagination for GET requests
    if ($All -and $Method -eq 'GET') {
        Write-Verbose "Automatic pagination enabled with page size $PageSize"

        # Add/update limit parameter in URI for first request (cross-platform)
        $currentQuery = $URI.Query.TrimStart('?')
        if ($currentQuery) {
            # Remove any existing limit parameter
            $currentQuery = ($currentQuery -split '&' | Where-Object { $_ -notmatch '^limit=' }) -join '&'
            $URI.Query = "$currentQuery&limit=$PageSize"
        }
        else {
            $URI.Query = "limit=$PageSize"
        }

        $allResults = [System.Collections.ArrayList]::new()
        $pageNum = 0
        $nextUrl = $null

        do {
            $pageNum++
            $currentUri = if ($nextUrl) {
                # Use the next URL from API response
                [System.UriBuilder]::new($nextUrl)
            }
            else {
                $URI
            }

            Write-Verbose "Fetching page ${pageNum}..."

            # Make single-page request (recursive call without -All)
            $pageResult = InvokeNetboxRequest -URI $currentUri -Headers $Headers -Body $Body `
                -Timeout $Timeout -Method $Method -Raw -MaxRetries $MaxRetries -RetryDelayMs $RetryDelayMs

            if ($pageResult.results) {
                $itemCount = $pageResult.results.Count
                [void]$allResults.AddRange($pageResult.results)
                Write-Verbose "Page ${pageNum}: Retrieved $itemCount items (Total: $($allResults.Count))"

                # Show progress for large datasets
                if ($pageResult.count -gt 0) {
                    $percentComplete = [Math]::Min(100, [int](($allResults.Count / $pageResult.count) * 100))
                    Write-Progress -Activity "Fetching all results" `
                        -Status "$($allResults.Count) of $($pageResult.count) items" `
                        -PercentComplete $percentComplete
                }
            }

            $nextUrl = $pageResult.next

        } while ($nextUrl)

        Write-Progress -Activity "Fetching all results" -Completed

        if ($Raw) {
            # Return a synthetic response object with all results
            return [PSCustomObject]@{
                count    = $allResults.Count
                next     = $null
                previous = $null
                results  = $allResults.ToArray()
            }
        }
        else {
            return $allResults.ToArray()
        }
    }

    # Retryable HTTP status codes
    $retryableStatusCodes = @(408, 429, 500, 502, 503, 504)

    $creds = Get-NBCredential
    $Headers.Authorization = "Token {0}" -f $creds.GetNetworkCredential().Password

    $splat = @{
        'Method'      = $Method
        'Uri'         = $URI.Uri.AbsoluteUri
        'Headers'     = $Headers
        'TimeoutSec'  = $Timeout
        'ContentType' = 'application/json'
        'ErrorAction' = 'Stop'
        'Verbose'     = $VerbosePreference
    }

    $splat += Get-NBInvokeParams

    if ($Body) {
        Write-Verbose "BODY: $($Body | ConvertTo-Json -Compress)"
        $null = $splat.Add('Body', ($Body | ConvertTo-Json -Compress -Depth 10))
    }

    $attempt = 0

    while ($attempt -lt $MaxRetries) {
        $attempt++

        try {
            Write-Verbose "[$attempt/$MaxRetries] $Method $($URI.Uri.AbsoluteUri)"
            $result = Invoke-RestMethod @splat

            # Success - return result
            if ($Raw) {
                Write-Verbose "Returning raw result by choice"
                return $result
            }
            else {
                if ($result.psobject.Properties.Name -contains 'results') {
                    Write-Verbose "Found 'results' property, returning results directly"
                    return $result.Results
                }
                else {
                    Write-Verbose "No 'results' property found, returning full response"
                    return $result
                }
            }
        }
        catch {
            $statusCode = $null
            $errorMessage = $_.Exception.Message
            $responseBody = $null

            # Extract status code and response body
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode

                # Use helper function for safe response body extraction (proper disposal)
                $responseBody = GetNetboxAPIErrorBody -Response $_.Exception.Response

                if ($responseBody) {
                    try {
                        $errorData = $responseBody | ConvertFrom-Json -ErrorAction Stop
                        if ($errorData.detail) {
                            $errorMessage = $errorData.detail
                        }
                        elseif ($errorData.error) {
                            $errorMessage = $errorData.error
                        }
                        elseif ($errorData) {
                            # Try to format the error object nicely
                            $errorMessage = ($errorData.PSObject.Properties | ForEach-Object {
                                "$($_.Name): $($_.Value -join ', ')"
                            }) -join '; '
                        }
                    }
                    catch {
                        # Use raw response body if JSON parsing fails
                        if ($responseBody.Length -lt 500) {
                            $errorMessage = $responseBody
                        }
                    }
                }
            }

            # Check if we should retry
            $shouldRetry = ($statusCode -in $retryableStatusCodes) -and ($attempt -lt $MaxRetries)

            if ($shouldRetry) {
                # Exponential backoff with jitter
                $delay = $RetryDelayMs * [Math]::Pow(2, $attempt - 1)
                $jitter = Get-Random -Minimum 0 -Maximum ($delay * 0.1)
                $totalDelay = [int]($delay + $jitter)

                $statusName = GetHttpStatusName -StatusCode $statusCode
                Write-Verbose "Retryable error ($statusCode $statusName). Waiting ${totalDelay}ms before retry..."
                Start-Sleep -Milliseconds $totalDelay
                continue
            }

            # Non-retryable error or max retries reached - throw detailed error
            $statusName = if ($statusCode) { GetHttpStatusName -StatusCode $statusCode } else { "Unknown" }

            $detailedMessage = BuildDetailedErrorMessage `
                -StatusCode $statusCode `
                -StatusName $statusName `
                -Method $Method `
                -Endpoint $URI.Uri.AbsoluteUri `
                -ErrorMessage $errorMessage

            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new($detailedMessage),
                "NetboxAPI.$statusCode",
                (GetErrorCategory -StatusCode $statusCode),
                $URI.Uri.AbsoluteUri
            )

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}

function GetHttpStatusName {
    [CmdletBinding()]
    [OutputType([string])]
    param([int]$StatusCode)

    $statusNames = @{
        400 = 'Bad Request'
        401 = 'Unauthorized'
        403 = 'Forbidden'
        404 = 'Not Found'
        405 = 'Method Not Allowed'
        408 = 'Request Timeout'
        409 = 'Conflict'
        429 = 'Too Many Requests'
        500 = 'Internal Server Error'
        502 = 'Bad Gateway'
        503 = 'Service Unavailable'
        504 = 'Gateway Timeout'
    }

    if ($statusNames.ContainsKey($StatusCode)) {
        return $statusNames[$StatusCode]
    }
    return "HTTP $StatusCode"
}

function GetErrorCategory {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorCategory])]
    param([int]$StatusCode)

    switch ($StatusCode) {
        400 { return [System.Management.Automation.ErrorCategory]::InvalidArgument }
        401 { return [System.Management.Automation.ErrorCategory]::AuthenticationError }
        403 { return [System.Management.Automation.ErrorCategory]::PermissionDenied }
        404 { return [System.Management.Automation.ErrorCategory]::ObjectNotFound }
        405 { return [System.Management.Automation.ErrorCategory]::InvalidOperation }
        408 { return [System.Management.Automation.ErrorCategory]::OperationTimeout }
        409 { return [System.Management.Automation.ErrorCategory]::ResourceExists }
        429 { return [System.Management.Automation.ErrorCategory]::LimitsExceeded }
        { $_ -ge 500 } { return [System.Management.Automation.ErrorCategory]::ConnectionError }
        default { return [System.Management.Automation.ErrorCategory]::InvalidOperation }
    }
}

function BuildDetailedErrorMessage {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [int]$StatusCode,
        [string]$StatusName,
        [string]$Method,
        [string]$Endpoint,
        [string]$ErrorMessage
    )

    $troubleshooting = switch ($StatusCode) {
        401 {
            @(
                "- Verify your API token is correct and not expired"
                "- Check token in Netbox: Admin > API Tokens"
                "- Ensure token has not been revoked"
            ) -join "`n"
        }
        403 {
            @(
                "- Verify your API token has permission for this operation"
                "- Check object-level permissions in Netbox"
                "- Ensure the token user has the required role"
            ) -join "`n"
        }
        404 {
            @(
                "- Verify the resource ID exists in Netbox"
                "- Check if the resource was deleted"
                "- Ensure the API endpoint is correct for your Netbox version"
            ) -join "`n"
        }
        429 {
            @(
                "- You are being rate limited by the API"
                "- Wait a moment and retry your request"
                "- Consider reducing request frequency"
            ) -join "`n"
        }
        { $_ -ge 500 } {
            @(
                "- This is a server-side error in Netbox"
                "- Check Netbox server logs for details"
                "- Verify Netbox service is running correctly"
                "- Try again in a few moments"
            ) -join "`n"
        }
        default {
            "- Check your request parameters`n- Verify the API endpoint exists"
        }
    }

    return @"
Netbox API Error: $StatusCode $StatusName
Endpoint: $Method $Endpoint
Message: $ErrorMessage

Troubleshooting:
$troubleshooting
"@
}
