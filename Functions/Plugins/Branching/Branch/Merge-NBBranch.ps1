<#
.SYNOPSIS
    Merges a branch into the main database.

.DESCRIPTION
    Merges all changes from a branch into the main Netbox database.
    After merging, the branch status changes to 'merged'.

.PARAMETER Id
    The ID of the branch to merge.

.PARAMETER Force
    Force merge even if conflicts exist.

.PARAMETER Raw
    Return the raw API response.

.OUTPUTS
    [PSCustomObject] The merged branch object.

.EXAMPLE
    Merge-NBBranch -Id 1
    Merge branch with ID 1 to main.

.EXAMPLE
    Get-NBBranch -Name "feature" | Merge-NBBranch -Confirm:$false
    Merge a branch without confirmation using pipeline.

.EXAMPLE
    Merge-NBBranch -Id 1 -Force
    Force merge even if there are conflicts.

.LINK
    Get-NBBranch
    Sync-NBBranch
    Undo-NBBranchMerge
#>
function Merge-NBBranch {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Processing Merge-NBBranch"
        CheckNetboxIsConnected

        # Check for conflicts unless Force is specified
        if (-not $Force) {
            $changes = Get-NBChangeDiff -Branch_Id $Id -ErrorAction SilentlyContinue
            $conflicts = $changes | Where-Object { $_.conflicts }

            if ($conflicts) {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new(
                        "Branch ID $Id has $($conflicts.Count) conflict(s). Use -Force to merge anyway, or resolve conflicts first."
                    ),
                    'BranchHasConflicts',
                    [System.Management.Automation.ErrorCategory]::ResourceExists,
                    $Id
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        $Segments = [System.Collections.ArrayList]::new(@('plugins', 'netbox-branching', 'branches', $Id, 'merge'))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess("Branch ID $Id", 'Merge Branch to Main')) {
            InvokeNetboxRequest -URI $URI -Method POST -Raw:$Raw
        }
    }
}
