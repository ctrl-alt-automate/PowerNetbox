
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

    .EXAMPLE
        PS C:\> Get-NBVirtualizationCluster
#>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [string]$Name,

        [Alias('q')]
        [string]$Query,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Group,

        [uint64]$Group_Id,

        [string]$Type,

        [uint64]$Type_Id,

        [string]$Site,

        [uint64]$Site_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Virtualization Cluster"
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

        $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
