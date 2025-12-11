<#
.SYNOPSIS
    Creates a new virtualization cluster in Netbox.

.DESCRIPTION
    Creates a new virtualization cluster in the Netbox virtualization module.
    Clusters represent a pool of resources (hypervisors) that host virtual machines.

.PARAMETER Name
    The name of the cluster.

.PARAMETER Type
    The database ID of the cluster type (e.g., VMware vSphere, KVM, Hyper-V).

.PARAMETER Group
    The database ID of the cluster group this cluster belongs to.

.PARAMETER Site
    The database ID of the site where this cluster is located.

.PARAMETER Status
    The operational status of the cluster: planned, staging, active, decommissioning, offline.

.PARAMETER Tenant
    The database ID of the tenant that owns this cluster.

.PARAMETER Description
    A description of the cluster.

.PARAMETER Comments
    Additional comments about the cluster.

.PARAMETER Tags
    Array of tag IDs to assign to this cluster.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualizationCluster -Name "Production vSphere" -Type 1

    Creates a new cluster with the specified name and type.

.EXAMPLE
    $type = Get-NBVirtualizationClusterType -Name "VMware vSphere"
    New-NBVirtualizationCluster -Name "DC1-Cluster" -Type $type.Id -Site 1 -Status "active"

    Creates a new active cluster associated with a site.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/cluster/
#>
function New-NBVirtualizationCluster {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
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

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create virtualization cluster')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
