function Get-NetboxDCIMLocation {
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
        Get-NetboxDCIMLocation

        Returns all locations

    .EXAMPLE
        Get-NetboxDCIMLocation -Site_Id 1

        Returns all locations at site with ID 1

    .EXAMPLE
        Get-NetboxDCIMLocation -Name "Server Room"

        Returns locations matching the name "Server Room"
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
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

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($LocationId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations', $LocationId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}
