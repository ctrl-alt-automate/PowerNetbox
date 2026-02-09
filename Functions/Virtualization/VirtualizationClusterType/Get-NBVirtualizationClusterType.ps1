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

.PARAMETER All
    Automatically fetch all pages of results. Uses the API's pagination
    to retrieve all items across multiple requests.

.PARAMETER PageSize
    Number of items per page when using -All. Default: 100.
    Range: 1-1000.

.PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

.PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name', 'device_type.model').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.


.EXAMPLE
    Get-NBVirtualizationClusterType

    Returns all cluster types.

.EXAMPLE
    Get-NBVirtualizationClusterType -Name "VMware*"

    Returns cluster types matching the name pattern.

.EXAMPLE
    Get-NBVirtualizationClusterType -Id 1

    Returns the cluster type with ID 1.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustertype/
#>
function Get-NBVirtualizationClusterType {
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

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Query')]
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
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('virtualization', 'cluster-types', $i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
