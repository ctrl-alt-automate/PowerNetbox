<#
.SYNOPSIS
    Retrieves owner groups from Netbox (Netbox 4.5+).

.DESCRIPTION
    Retrieves owner groups from Netbox Users module.
    Owner groups are used to organize owners for object ownership tracking.
    This endpoint is only available in Netbox 4.5 and later.

.PARAMETER Id
    Database ID of the owner group.

.PARAMETER Name
    Filter by name.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER All
    Retrieve all owner groups (pagination handled automatically).

.PARAMETER PageSize
    Number of results per page (1-1000, default 100).

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBOwnerGroup

.EXAMPLE
    Get-NBOwnerGroup -Name "Network Team"

.EXAMPLE
    Get-NBOwnerGroup -Id 5

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBOwnerGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('users', 'owner-groups', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('users', 'owner-groups'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
