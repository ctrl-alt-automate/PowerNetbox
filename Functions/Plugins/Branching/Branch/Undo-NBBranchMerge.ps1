<#
.SYNOPSIS
    Reverts a merged branch.

.DESCRIPTION
    Reverts a branch that was previously merged, undoing all the changes
    that were applied to the main database.

.PARAMETER Id
    The ID of the merged branch to revert.

.PARAMETER Raw
    Return the raw API response.

.OUTPUTS
    [PSCustomObject] The reverted branch object.

.EXAMPLE
    Undo-NBBranchMerge -Id 1
    Revert the merge of branch ID 1.

.EXAMPLE
    Get-NBBranch -Status merged | Undo-NBBranchMerge
    Revert all merged branches (use with caution!).

.LINK
    Merge-NBBranch
    Get-NBBranch
#>
function Undo-NBBranchMerge {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Processing Undo-NBBranch Merge"
        CheckNetboxIsConnected

        $Segments = [System.Collections.ArrayList]::new(@('plugins', 'branching', 'branches', $Id, 'revert'))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess("Branch ID $Id", 'Revert Merged Branch')) {
            InvokeNetboxRequest -URI $URI -Method POST -Raw:$Raw
        }
    }
}
