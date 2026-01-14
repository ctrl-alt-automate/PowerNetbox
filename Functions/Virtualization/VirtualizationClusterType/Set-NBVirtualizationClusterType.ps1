<#
.SYNOPSIS
    Updates an existing virtualization cluster type in Netbox.

.DESCRIPTION
    Updates an existing cluster type in the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationClusterType.

.PARAMETER Id
    The database ID of the cluster type to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the cluster type.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Description
    A description of the cluster type.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualizationClusterType -Id 1 -Description "VMware vSphere 8.0"

    Updates the description of cluster type ID 1.

.EXAMPLE
    Get-NBVirtualizationClusterType -Slug "kvm" | Set-NBVirtualizationClusterType -Name "KVM/QEMU"

    Updates a cluster type found by slug via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustertype/
#>
function Set-NBVirtualizationClusterType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Virtualization Cluster Type"
        foreach ($TypeId in $Id) {
            $CurrentType = Get-NBVirtualizationClusterType -Id $TypeId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-types', $CurrentType.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentType.Name)", 'Update cluster type')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}
