
function InvokeNetboxRequest {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.UriBuilder]$URI,

        [Hashtable]$Headers = @{
        },

        [pscustomobject]$Body = $null,

        [ValidateRange(1, 65535)]
        [uint16]$Timeout = (Get-NBTimeout),

        [ValidateSet('GET', 'PATCH', 'PUT', 'POST', 'DELETE', 'OPTIONS', IgnoreCase = $true)]
        [string]$Method = 'GET',

        [switch]$Raw
    )

    $creds = Get-NBCredential

    $Headers.Authorization = "Token {0}" -f $creds.GetNetworkCredential().Password

    $splat = @{
        'Method'      = $Method
        'Uri'         = $URI.Uri.AbsoluteUri # This property auto generates the scheme, hostname, path, and query
        'Headers'     = $Headers
        'TimeoutSec'  = $Timeout
        'ContentType' = 'application/json'
        'ErrorAction' = 'Stop'
        'Verbose'     = $VerbosePreference
    }

    $splat += Get-NBInvokeParams

    if ($Body) {
        Write-Verbose "BODY: $($Body | ConvertTo-Json -Compress)"
        $null = $splat.Add('Body', ($Body | ConvertTo-Json -Compress))
    }

    try {
        Write-Verbose "Sending request to $($URI.Uri.AbsoluteUri)"
        $result = Invoke-RestMethod @splat
    } catch {
        $errorMessage = $_.Exception.Message
        $statusCode = $null

        # Try to extract response body for better error messages
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode

            try {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = [System.IO.StreamReader]::new($stream)
                $responseBody = $reader.ReadToEnd()
                $reader.Close()

                if ($responseBody) {
                    $errorData = $responseBody | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($errorData.detail) {
                        $errorMessage = $errorData.detail
                    } elseif ($errorData) {
                        $errorMessage = $responseBody
                    }
                }
            } catch {
                # Keep original error message if we can't parse response
                Write-Verbose "Could not parse error response body: $_"
            }
        }

        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.Exception]::new("Netbox API Error ($statusCode): $errorMessage"),
            'NetboxAPIError',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $URI.Uri.AbsoluteUri
        )
        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }

    # If the user wants the raw value from the API... otherwise return only the actual result
    if ($Raw) {
        Write-Verbose "Returning raw result by choice"
        return $result
    } else {
        if ($result.psobject.Properties.Name.Contains('results')) {
            Write-Verbose "Found Results property on data, returning results directly"
            return $result.Results
        } else {
            Write-Verbose "Did NOT find results property on data, returning raw result"
            return $result
        }
    }
}