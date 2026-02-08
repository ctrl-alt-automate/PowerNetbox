<#
.SYNOPSIS
    Removes a virtualization cluster from Netbox.

.DESCRIPTION
    Removes a virtualization cluster from the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationCluster.
    Warning: This will also remove all VMs associated with the cluster.

.PARAMETER Id
    The database ID(s) of the cluster(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualizationCluster -Id 1

    Removes cluster ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBVirtualizationCluster -Id 1, 2, 3 -Force

    Removes multiple clusters without confirmation.

.EXAMPLE
    Get-NBVirtualizationCluster -Name "test-*" | Remove-NBVirtualizationCluster

    Removes all clusters matching the name pattern via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/cluster/
#>
function Remove-NBVirtualizationCluster {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Virtualization Cluster"
        foreach ($ClusterId in $Id) {

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'clusters', $ClusterId))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("ID $ClusterId", 'Delete cluster')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
