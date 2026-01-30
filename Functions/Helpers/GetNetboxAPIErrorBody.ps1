function GetNetboxAPIErrorBody {
    <#
    .SYNOPSIS
        Extracts the response body and content type from a failed HTTP response.

    .DESCRIPTION
        Safely extracts and returns the response body and content type from an HTTP error response.
        Cross-platform compatible: handles both HttpWebResponse (PowerShell Desktop)
        and HttpResponseMessage (PowerShell Core).

        Returns a PSCustomObject with Body, ContentType, and IsJson properties to help
        callers properly handle different error response formats (JSON from Netbox,
        HTML from proxies, etc.).

    .PARAMETER Response
        The HTTP response object from a failed API call.
        Accepts both System.Net.HttpWebResponse (Desktop) and
        System.Net.Http.HttpResponseMessage (Core).

    .OUTPUTS
        [PSCustomObject] Object with Body (string), ContentType (string), and IsJson (bool).

    .EXAMPLE
        $errorResponse = GetNetboxAPIErrorBody -Response $_.Exception.Response
        if ($errorResponse.IsJson) {
            $errorData = $errorResponse.Body | ConvertFrom-Json
        }

    .NOTES
        Fixes issue #100: Cross-platform error handling compatibility.
        Fixes issue #154: Content-Type check for proxy error handling.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        $Response  # No type constraint - accept both HttpWebResponse and HttpResponseMessage
    )

    $result = [PSCustomObject]@{
        Body        = [string]::Empty
        ContentType = $null
        IsJson      = $false
    }

    try {
        # PowerShell Core (7.x) - HttpClient-based response
        if ($Response -is [System.Net.Http.HttpResponseMessage]) {
            Write-Verbose "Extracting error body from HttpResponseMessage (PowerShell Core)"

            # Extract Content-Type header
            $result.ContentType = $Response.Content.Headers.ContentType.MediaType

            $result.Body = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        }
        # PowerShell Desktop (5.1) - WebRequest-based response
        elseif ($Response -is [System.Net.HttpWebResponse]) {
            Write-Verbose "Extracting error body from HttpWebResponse (PowerShell Desktop)"

            # Extract Content-Type header
            $result.ContentType = $Response.ContentType

            $stream = $null
            $reader = $null

            try {
                $stream = $Response.GetResponseStream()

                if ($null -eq $stream) {
                    return $result
                }

                # Explicitly specify UTF-8 encoding for cross-platform consistency
                $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)

                # Some streams support seeking, reset position if possible
                if ($stream.CanSeek) {
                    $stream.Position = 0
                }

                $result.Body = $reader.ReadToEnd()
            }
            finally {
                # Proper disposal in reverse order of creation
                if ($null -ne $reader) {
                    $reader.Dispose()
                }
                if ($null -ne $stream) {
                    $stream.Dispose()
                }
            }
        }
        else {
            Write-Verbose "Unknown response type: $($Response.GetType().FullName)"
            return $result
        }

        # Determine if response is JSON based on Content-Type or content inspection
        if ($result.ContentType -like '*json*') {
            $result.IsJson = $true
        }
        elseif ($result.Body -and ($result.Body.TrimStart() -match '^[\{\[]')) {
            # Content starts with { or [ - likely JSON even without proper Content-Type
            $result.IsJson = $true
        }

        Write-Verbose "Error response Content-Type: $($result.ContentType), IsJson: $($result.IsJson)"
    }
    catch {
        Write-Verbose "Could not read response body: $($_.Exception.Message)"
    }

    return $result
}
