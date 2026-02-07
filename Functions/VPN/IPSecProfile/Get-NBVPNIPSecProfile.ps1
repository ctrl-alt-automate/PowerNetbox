<#
.SYNOPSIS
    Retrieves IPSec Profile objects from Netbox VPN module.

.DESCRIPTION
    Retrieves IPSec Profile objects from Netbox VPN module.

.PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

.PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.


.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNIPSecProfile

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNIPSecProfile {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,


        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving VPN IPSec Profile"

        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('vpn', 'ipsec-profiles', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('vpn', 'ipsec-profiles'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
