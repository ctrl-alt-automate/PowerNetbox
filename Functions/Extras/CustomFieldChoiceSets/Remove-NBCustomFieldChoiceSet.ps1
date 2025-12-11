<#
.SYNOPSIS
    Removes a custom field choice set from Netbox.

.DESCRIPTION
    Deletes a custom field choice set from Netbox by ID.

.PARAMETER Id
    The ID of the choice set to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCustomFieldChoiceSet -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCustomFieldChoiceSet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Custom Field Choice Set')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
