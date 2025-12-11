<#
.SYNOPSIS
    Removes a custom link from Netbox.

.DESCRIPTION
    Deletes a custom link from Netbox by ID.

.PARAMETER Id
    The ID of the custom link to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCustomLink -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCustomLink {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-links', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Custom Link')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
