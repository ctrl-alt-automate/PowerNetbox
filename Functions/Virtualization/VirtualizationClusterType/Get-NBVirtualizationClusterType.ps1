<#
.SYNOPSIS
    Retrieves virtualization cluster types from Netbox.

.DESCRIPTION
    Retrieves cluster types from the Netbox virtualization module.
    Cluster types define the virtualization technology (e.g., VMware vSphere, KVM, Hyper-V).

.PARAMETER Id
    Database ID(s) of the cluster type to retrieve. Accepts pipeline input.

.PARAMETER Name
    Filter by cluster type name.

.PARAMETER Slug
    Filter by cluster type slug.

.PARAMETER Description
    Filter by description.

.PARAMETER Query
    General search query.

.PARAMETER Limit
    Maximum number of results to return (1-1000).

.PARAMETER Offset
    Number of results to skip for pagination.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVVirtualization ClusterType

    Returns all cluster types.

.EXAMPLE
    Get-NBVVirtualization ClusterType -Name "VMware*"

    Returns cluster types matching the name pattern.

.EXAMPLE
    Get-NBVVirtualization ClusterType -Id 1

    Returns the cluster type with ID 1.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustertype/
#>
function Get-NBVVirtualization ClusterType {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [Alias('q')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Virtualization Cluster Type"
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-types'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
