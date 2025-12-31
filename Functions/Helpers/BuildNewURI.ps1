
function BuildNewURI {
<#
    .SYNOPSIS
        Create a new URI for Netbox

    .DESCRIPTION
        Internal function used to build a URIBuilder object.

    .PARAMETER Hostname
        Hostname of the Netbox API

    .PARAMETER Segments
        Array of strings for each segment in the URL path

    .PARAMETER Parameters
        Hashtable of query parameters to include

    .PARAMETER HTTPS
        Whether to use HTTPS or HTTP

    .EXAMPLE
        PS C:\> BuildNewURI -Segments @('dcim', 'devices')
#>

    [CmdletBinding()]
    [OutputType([System.UriBuilder])]
    param
    (
        [Parameter(Mandatory = $false)]
        [string[]]$Segments,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters,

        [switch]$SkipConnectedCheck
    )

    Write-Verbose "Building URI"

    if (-not $SkipConnectedCheck) {
        # There is no point in continuing if we have not successfully connected to an API
        $null = CheckNetboxIsConnected
    }

    # Begin a URI builder with HTTP/HTTPS and the provided hostname
    $uriBuilder = [System.UriBuilder]::new($script:NetboxConfig.HostScheme, $script:NetboxConfig.Hostname, $script:NetboxConfig.HostPort)

    # Generate the path by trimming excess slashes and whitespace from the $segments[] and joining together
    $uriBuilder.Path = "api/{0}/" -f ($Segments.ForEach({
                $_.trim('/').trim()
            }) -join '/')

    Write-Verbose " URIPath: $($uriBuilder.Path)"

    if ($parameters) {
        # Build query string without System.Web dependency (cross-platform)
        $QueryParts = [System.Collections.Generic.List[string]]::new()

        foreach ($param in $Parameters.GetEnumerator()) {
            Write-Verbose " Adding URI parameter $($param.Key):$($param.Value)"
            # URL encode key and value using .NET Uri class (available everywhere)
            $EncodedKey = [System.Uri]::EscapeDataString($param.Key)
            $EncodedValue = [System.Uri]::EscapeDataString([string]$param.Value)
            $QueryParts.Add("$EncodedKey=$EncodedValue")
        }

        $uriBuilder.Query = $QueryParts -join '&'
    }

    Write-Verbose " Completed building URIBuilder"
    # Return the entire UriBuilder object
    $uriBuilder
}