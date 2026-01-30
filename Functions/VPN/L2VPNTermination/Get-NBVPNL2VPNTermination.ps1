<#
.SYNOPSIS
    Retrieves L2VPNTermination objects from Netbox VPN module.

.DESCRIPTION
    Retrieves L2VPNTermination objects from Netbox VPN module.

.PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

.PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name').

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNL2VPNTermination

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNL2VPNTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$L2VPN_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving VPN L2VPN Termination"

        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($i in $Id) {
                    InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn', 'l2vpn-terminations', $i)) -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('vpn', 'l2vpn-terminations'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}
