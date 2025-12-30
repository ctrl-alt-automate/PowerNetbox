<#
.SYNOPSIS
    Removes a circuit group assignment from Netbox.

.DESCRIPTION
    Deletes a circuit group assignment from Netbox by ID.

.PARAMETER Id
    The ID of the assignment to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitGroupAssignment -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitGroupAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Circuit Group Assignment"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-group-assignments', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Group Assignment')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
