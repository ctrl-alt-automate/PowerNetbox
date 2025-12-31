<#
.SYNOPSIS
    Synchronizes a branch with the main database.

.DESCRIPTION
    Syncs a branch with the latest changes from the main database.
    This brings in any changes made to main since the branch was created.

.PARAMETER Id
    The ID of the branch to sync.

.PARAMETER Raw
    Return the raw API response.

.OUTPUTS
    [PSCustomObject] The synced branch object.

.EXAMPLE
    Sync-NBBranch -Id 1
    Sync branch with ID 1 to latest main.

.EXAMPLE
    Get-NBBranch -Name "feature" | Sync-NBBranch
    Sync a branch using pipeline.

.LINK
    Get-NBBranch
    Merge-NBBranch
#>
function Sync-NBBranch {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Processing Sync-NBBranch"
        CheckNetboxIsConnected

        $Segments = [System.Collections.ArrayList]::new(@('plugins', 'netbox-branching', 'branches', $Id, 'sync'))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess("Branch ID $Id", 'Sync Branch')) {
            InvokeNetboxRequest -URI $URI -Method POST -Raw:$Raw
        }
    }
}
