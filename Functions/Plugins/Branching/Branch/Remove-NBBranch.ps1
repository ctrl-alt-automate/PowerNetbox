<#
.SYNOPSIS
    Deletes a branch from Netbox.

.DESCRIPTION
    Deletes a branch using the Netbox Branching plugin.
    This action cannot be undone and any unmerged changes will be lost.

.PARAMETER Id
    The ID of the branch to delete.

.PARAMETER Raw
    Return the raw API response.

.OUTPUTS
    None, or raw response if -Raw is specified.

.EXAMPLE
    Remove-NBBranch -Id 1
    Delete branch with ID 1 (with confirmation).

.EXAMPLE
    Get-NBBranch -Name "old-branch" | Remove-NBBranch -Confirm:$false
    Delete branch without confirmation using pipeline.

.LINK
    Get-NBBranch
    New-NBBranch
#>
function Remove-NBBranch {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Branch"
        CheckNetboxIsConnected

        $Segments = [System.Collections.ArrayList]::new(@('plugins', 'branching', 'branches', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess("Branch ID $Id", 'Delete Branch')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
