<#
.SYNOPSIS
    Removes a virtualization cluster group from Netbox.

.DESCRIPTION
    Removes a cluster group from the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationClusterGroup.

.PARAMETER Id
    The database ID(s) of the cluster group(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualizationClusterGroup -Id 1

    Removes cluster group ID 1 (with confirmation prompt).

.EXAMPLE
    Get-NBVirtualizationClusterGroup | Where-Object { $_.cluster_count -eq 0 } | Remove-NBVirtualizationClusterGroup -Force

    Removes all empty cluster groups without confirmation.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustergroup/
#>
function Remove-NBVirtualizationClusterGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Virtualization Cluster Group"
        foreach ($GroupId in $Id) {
            $CurrentGroup = Get-NBVirtualizationClusterGroup -Id $GroupId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-groups', $CurrentGroup.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentGroup.Name)", 'Delete cluster group')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
