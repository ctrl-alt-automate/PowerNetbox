<#
.SYNOPSIS
    Updates an existing virtualization cluster group in Netbox.

.DESCRIPTION
    Updates an existing cluster group in the Netbox virtualization module.
    Supports pipeline input from Get-NBVVirtualization ClusterGroup.

.PARAMETER Id
    The database ID of the cluster group to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the cluster group.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Description
    A description of the cluster group.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVVirtualization ClusterGroup -Id 1 -Description "Updated description"

    Updates the description of cluster group ID 1.

.EXAMPLE
    Get-NBVVirtualization ClusterGroup -Name "prod" | Set-NBVVirtualization ClusterGroup -Name "Production"

    Updates a cluster group found by name via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustergroup/
#>
function Set-NBVirtualizationClusterGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Virtualization Cluster Group"
        foreach ($GroupId in $Id) {
            $CurrentGroup = Get-NBVVirtualization ClusterGroup -Id $GroupId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups', $CurrentGroup.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentGroup.Name)", 'Update cluster group')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}
