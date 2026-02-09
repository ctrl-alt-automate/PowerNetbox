
function Get-NBVirtualizationCluster {
<#
    .SYNOPSIS
        Obtains virtualization clusters from Netbox.

    .DESCRIPTION
        Obtains one or more virtualization clusters based on provided filters.

    .PARAMETER Limit
        Number of results to return per page

    .PARAMETER Offset
        The initial index from which to return the results

    .PARAMETER Query
        A general query used to search for a cluster

    .PARAMETER Name
        Name of the cluster

    .PARAMETER Id
        Database ID(s) of the cluster

    .PARAMETER Group
        String value of the cluster group.

    .PARAMETER Group_Id
        Database ID of the cluster group.

    .PARAMETER Type
        String value of the Cluster type.

    .PARAMETER Type_Id
        Database ID of the cluster type.

    .PARAMETER Site
        String value of the site.

    .PARAMETER Site_Id
        Database ID of the site.

    .PARAMETER Raw
        Return the raw API response instead of extracting the results array.

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
        PS C:\> Get-NBVirtualizationCluster
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

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('q')]
        [string]$Query,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Type_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Virtualization Cluster"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('virtualization', 'clusters', $i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters'))
                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
