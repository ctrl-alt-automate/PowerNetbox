function Get-NBDDCIM Rack {
<#
    .SYNOPSIS
        Get racks from Netbox

    .DESCRIPTION
        Retrieves rack objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the rack to retrieve

    .PARAMETER Name
        Filter by rack name

    .PARAMETER Query
        A general search query

    .PARAMETER Site_Id
        Filter by site ID

    .PARAMETER Site
        Filter by site name

    .PARAMETER Location_Id
        Filter by location ID

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Status
        Filter by status (active, planned, reserved, deprecated)

    .PARAMETER Role_Id
        Filter by role ID

    .PARAMETER Serial
        Filter by serial number

    .PARAMETER Asset_Tag
        Filter by asset tag

    .PARAMETER Facility_Id
        Filter by facility ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NBDDCIM Rack

        Returns all racks

    .EXAMPLE
        Get-NBDDCIM Rack -Site_Id 1

        Returns all racks at site with ID 1

    .EXAMPLE
        Get-NBDDCIM Rack -Name "Rack-01"

        Returns racks matching the name "Rack-01"
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
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Location_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('active', 'planned', 'reserved', 'deprecated')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Serial,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Asset_Tag,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Facility_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving DCIM Rack"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RackId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks', $RackId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
