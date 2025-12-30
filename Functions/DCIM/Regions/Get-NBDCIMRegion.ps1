function Get-NBDCIMRegion {
<#
    .SYNOPSIS
        Get regions from Netbox

    .DESCRIPTION
        Retrieves region objects from Netbox with optional filtering.
        Regions are used to organize sites geographically (e.g., countries, states, cities).

    .PARAMETER Id
        The ID of the region to retrieve

    .PARAMETER Name
        Filter by region name

    .PARAMETER Query
        A general search query

    .PARAMETER Slug
        Filter by slug

    .PARAMETER Parent_Id
        Filter by parent region ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NBDCIMRegion

        Returns all regions

    .EXAMPLE
        Get-NBDCIMRegion -Name "Europe"

        Returns regions matching the name "Europe"

    .EXAMPLE
        Get-NBDCIMRegion -Parent_Id 1

        Returns all child regions of region 1
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

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
        [uint64]$Parent_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving D CI MR eg io n"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RegionId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions', $RegionId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
