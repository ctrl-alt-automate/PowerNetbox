<#
.SYNOPSIS
    Retrieves Virtualization Cluster objects from Netbox Virtualization module.

.DESCRIPTION
    Retrieves Virtualization Cluster objects from Netbox Virtualization module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVirtualizationClusterGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVirtualizationClusterGroup {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [string]$Query,

        [uint64[]]$Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

    $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

    InvokeNetboxRequest -URI $uri -Raw:$Raw
}