<#
.SYNOPSIS
    Updates an existing virtualization cluster in Netbox.

.DESCRIPTION
    Updates an existing virtualization cluster in the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationCluster.

.PARAMETER Id
    The database ID of the cluster to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the cluster.

.PARAMETER Type
    The database ID of the cluster type.

.PARAMETER Group
    The database ID of the cluster group.

.PARAMETER Site
    The database ID of the site.

.PARAMETER Status
    The operational status: planned, staging, active, decommissioning, offline.

.PARAMETER Tenant
    The database ID of the tenant.

.PARAMETER Description
    A description of the cluster.

.PARAMETER Comments
    Additional comments about the cluster.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualizationCluster -Id 1 -Description "Updated description"

    Updates the description of cluster ID 1.

.EXAMPLE
    Get-NBVirtualizationCluster -Name "prod-cluster" | Set-NBVirtualizationCluster -Status "active"

    Updates a cluster found by name via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/cluster/
#>
function Set-NBVirtualizationCluster {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64]$Type,

        [uint64]$Group,

        [uint64]$Site,

        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'offline', IgnoreCase = $true)]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Virtualization Cluster"
        foreach ($ClusterId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters', $ClusterId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("Cluster ID $ClusterId", 'Update cluster')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}
