function Get-NBIPAMASN {
<#
    .SYNOPSIS
        Get ASNs from Netbox

    .DESCRIPTION
        Retrieves ASN (Autonomous System Number) objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the ASN to retrieve

    .PARAMETER ASN
        Filter by ASN number

    .PARAMETER Query
        A general search query

    .PARAMETER RIR_Id
        Filter by RIR ID

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Site_Id
        Filter by site ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NBIPAMASN

        Returns all ASNs

    .EXAMPLE
        Get-NBIPAMASN -ASN 65001

        Returns ASN 65001
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
        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$ASN,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$RIR_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving IPAM ASN"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($ASNId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns', $ASNId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
