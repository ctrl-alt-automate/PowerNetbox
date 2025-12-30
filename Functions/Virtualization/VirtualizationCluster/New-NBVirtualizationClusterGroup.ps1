<#
.SYNOPSIS
    Creates a new virtualization cluster group in Netbox.

.DESCRIPTION
    Creates a new cluster group in the Netbox virtualization module.
    Cluster groups are organizational containers for grouping related clusters.

.PARAMETER Name
    The name of the cluster group.

.PARAMETER Slug
    URL-friendly unique identifier. If not provided, will be auto-generated from name.

.PARAMETER Description
    A description of the cluster group.

.PARAMETER Tags
    Array of tag IDs to assign to this cluster group.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVVirtualization ClusterGroup -Name "Production Clusters" -Slug "production-clusters"

    Creates a new cluster group with the specified name and slug.

.EXAMPLE
    New-NBVVirtualization ClusterGroup -Name "DR Sites" -Description "Disaster recovery clusters"

    Creates a new cluster group with auto-generated slug.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustergroup/
#>
function New-NBVVirtualization ClusterGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Virtualization Cluster Group"
        # Auto-generate slug from name if not provided
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }

        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create cluster group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
