function GetNetboxAPIErrorBody {
    <#
    .SYNOPSIS
        Extracts the response body from a failed HTTP response.

    .DESCRIPTION
        Safely extracts and returns the response body from an HTTP error response.
        Cross-platform compatible: handles both HttpWebResponse (PowerShell Desktop)
        and HttpResponseMessage (PowerShell Core).

    .PARAMETER Response
        The HTTP response object from a failed API call.
        Accepts both System.Net.HttpWebResponse (Desktop) and
        System.Net.Http.HttpResponseMessage (Core).

    .OUTPUTS
        [string] The response body content, or empty string if extraction fails.

    .EXAMPLE
        $body = GetNetboxAPIErrorBody -Response $_.Exception.Response

    .NOTES
        Fixes issue #100: Cross-platform error handling compatibility.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        $Response  # No type constraint - accept both HttpWebResponse and HttpResponseMessage
    )

    try {
        # PowerShell Core (7.x) - HttpClient-based response
        if ($Response -is [System.Net.Http.HttpResponseMessage]) {
            Write-Verbose "Extracting error body from HttpResponseMessage (PowerShell Core)"
            return $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        }
        # PowerShell Desktop (5.1) - WebRequest-based response
        elseif ($Response -is [System.Net.HttpWebResponse]) {
            Write-Verbose "Extracting error body from HttpWebResponse (PowerShell Desktop)"
            $stream = $null
            $reader = $null

            try {
                $stream = $Response.GetResponseStream()

                if ($null -eq $stream) {
                    return [string]::Empty
                }

                # Explicitly specify UTF-8 encoding for cross-platform consistency
                $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)

                # Some streams support seeking, reset position if possible
                if ($stream.CanSeek) {
                    $stream.Position = 0
                }

                return $reader.ReadToEnd()
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
            return [string]::Empty
        }
    }
    catch {
        Write-Verbose "Could not read response body: $($_.Exception.Message)"
        return [string]::Empty
    }
}
