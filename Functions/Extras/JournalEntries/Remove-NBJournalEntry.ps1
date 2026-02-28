<#
.SYNOPSIS
    Removes a journal entry from Netbox.

.DESCRIPTION
    Deletes a journal entry from Netbox by ID.

.PARAMETER Id
    The ID of the journal entry to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBJournalEntry -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBJournalEntry {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Journal Entry"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Journal Entry')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
