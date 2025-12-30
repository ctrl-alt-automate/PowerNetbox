
function Get-NBIPAMPrefix {
<#
    .SYNOPSIS
        Retrieves IP prefixes from Netbox IPAM module.

    .DESCRIPTION
        Retrieves IP prefix objects from Netbox. Prefixes represent IP network ranges
        (IPv4 or IPv6) and can be organized hierarchically within VRFs.

    .PARAMETER Query
        General search query to match prefixes.

    .PARAMETER Id
        Database ID of the prefix.

    .PARAMETER Limit
        Maximum number of results to return (1-1000).

    .PARAMETER Offset
        Number of results to skip for pagination.

    .PARAMETER Family
        IP address family (4 for IPv4, 6 for IPv6).

    .PARAMETER Is_Pool
        Filter for prefixes marked as IP pools.

    .PARAMETER Within
        Return prefixes within a parent prefix (CIDR notation, e.g., '10.0.0.0/16').

    .PARAMETER Within_Include
        Return prefixes within or equal to a prefix (CIDR notation, e.g., '10.0.0.0/16').

    .PARAMETER Contains
        Return prefixes containing an IP or subnet.

    .PARAMETER Mask_Length
        CIDR mask length value.

    .PARAMETER VRF
        Filter by VRF name.

    .PARAMETER VRF_Id
        Filter by VRF database ID.

    .PARAMETER Tenant
        Filter by tenant name.

    .PARAMETER Tenant_Id
        Filter by tenant database ID.

    .PARAMETER Site
        Filter by site name.

    .PARAMETER Site_Id
        Filter by site database ID.

    .PARAMETER Vlan_VId
        Filter by VLAN ID number.

    .PARAMETER Vlan_Id
        Filter by VLAN database ID.

    .PARAMETER Status
        Filter by prefix status (e.g., 'active', 'reserved', 'deprecated').

    .PARAMETER Role
        Filter by IPAM role name.

    .PARAMETER Role_Id
        Filter by IPAM role database ID.

    .PARAMETER Raw
        Return the raw API response instead of extracting the results array.

    .EXAMPLE
        PS C:\> Get-NBIPAMPrefix
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Prefix,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [boolean]$Is_Pool,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Within,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Within_Include,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contains,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateRange(0, 127)]
        [byte]$Mask_Length,

        [Parameter(ParameterSetName = 'Query')]
        [string]$VRF,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Vlan_VId,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Vlan_Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        #    if ($null -ne $Family) {
        #        $PSBoundParameters.Family = ValidateIPAMChoice -ProvidedValue $Family -PrefixFamily
        #    }
        #
        #    if ($null -ne $Status) {
        #        $PSBoundParameters.Status = ValidateIPAMChoice -ProvidedValue $Status -PrefixStatus
        #    }

        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Prefix_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $Prefix_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}
