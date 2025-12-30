<#
.SYNOPSIS
    Removes a virtualization cluster type from Netbox.

.DESCRIPTION
    Removes a cluster type from the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualizationClusterType.

.PARAMETER Id
    The database ID(s) of the cluster type(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualizationClusterType -Id 1

    Removes cluster type ID 1 (with confirmation prompt).

.EXAMPLE
    Get-NBVirtualizationClusterType | Where-Object { $_.cluster_count -eq 0 } | Remove-NBVirtualizationClusterType -Force

    Removes all unused cluster types without confirmation.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/clustertype/
#>
function Remove-NBVirtualizationClusterType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Virtualization Cluster Type"
        foreach ($TypeId in $Id) {
            $CurrentType = Get-NBVirtualizationClusterType -Id $TypeId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'cluster-types', $CurrentType.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentType.Name)", 'Delete cluster type')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
