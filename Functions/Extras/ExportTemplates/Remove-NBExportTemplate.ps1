<#
.SYNOPSIS
    Removes an export template from Netbox.

.DESCRIPTION
    Deletes an export template from Netbox by ID.

.PARAMETER Id
    The ID of the export template to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBExportTemplate -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBExportTemplate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'export-templates', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Export Template')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
