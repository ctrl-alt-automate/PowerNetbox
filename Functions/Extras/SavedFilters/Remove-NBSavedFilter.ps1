<#
.SYNOPSIS
    Removes a saved filter from Netbox.

.DESCRIPTION
    Deletes a saved filter from Netbox by ID.

.PARAMETER Id
    The ID of the saved filter to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBSavedFilter -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBSavedFilter {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Saved Filter"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'saved-filters', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Saved Filter')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
