function GetNetboxAPIErrorBody {
    <#
    .SYNOPSIS
        Extracts the response body from a failed HTTP response.

    .DESCRIPTION
        Safely extracts and returns the response body from an HttpWebResponse,
        properly disposing of stream resources to prevent memory leaks.
        Cross-platform compatible with proper UTF-8 encoding.

    .PARAMETER Response
        The HttpWebResponse object from a failed API call.

    .OUTPUTS
        [string] The response body content, or empty string if extraction fails.

    .EXAMPLE
        $body = GetNetboxAPIErrorBody -Response $_.Exception.Response
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Net.HttpWebResponse]$Response
    )

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
    catch {
        Write-Verbose "Could not read response body: $($_.Exception.Message)"
        return [string]::Empty
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
