<#
.SYNOPSIS
    Removes a custom field from Netbox.

.DESCRIPTION
    Deletes a custom field from Netbox by ID.

.PARAMETER Id
    The ID of the custom field to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCustomField -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCustomField {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Custom Field"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Custom Field')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
