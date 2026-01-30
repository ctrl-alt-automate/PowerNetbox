function Get-NBIPAMRouteTarget {
<#
    .SYNOPSIS
        Get route targets from Netbox

    .DESCRIPTION
        Retrieves route target objects from Netbox with optional filtering.
        Route targets are used for VRF import/export policies.

    .PARAMETER Id
        The ID of the route target to retrieve

    .PARAMETER Name
        Filter by route target name (RFC 4360 format)

    .PARAMETER Query
        A general search query

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Tenant
        Filter by tenant name

    .PARAMETER Importing_VRF_Id
        Filter by VRF ID that imports this target

    .PARAMETER Exporting_VRF_Id
        Filter by VRF ID that exports this target

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NBIPAMRouteTarget

        Returns all route targets

    .EXAMPLE
        Get-NBIPAMRouteTarget -Name "65001:100"

        Returns route targets matching the specified value
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
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Importing_VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Exporting_VRF_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving IPAM Route Target"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RTId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets', $RTId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
