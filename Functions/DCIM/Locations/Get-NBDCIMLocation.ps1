function Get-NBDCIMLocation {
<#
    .SYNOPSIS
        Get locations from Netbox

    .DESCRIPTION
        Retrieves location objects from Netbox with optional filtering.
        Locations represent physical areas within a site (e.g., floors, rooms, cages).

    .PARAMETER Id
        The ID of the location to retrieve

    .PARAMETER Name
        Filter by location name

    .PARAMETER Query
        A general search query

    .PARAMETER Slug
        Filter by slug

    .PARAMETER Site_Id
        Filter by site ID

    .PARAMETER Site
        Filter by site name

    .PARAMETER Parent_Id
        Filter by parent location ID

    .PARAMETER Status
        Filter by status (planned, staging, active, decommissioning, retired)

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NBDCIMLocation

        Returns all locations

    .EXAMPLE
        Get-NBDCIMLocation -Site_Id 1

        Returns all locations at site with ID 1

    .EXAMPLE
        Get-NBDCIMLocation -Name "Server Room"

        Returns locations matching the name "Server Room"
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Parent_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'retired')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving DCIM Location"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($LocationId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations', $LocationId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
