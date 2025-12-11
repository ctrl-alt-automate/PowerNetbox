<#
.SYNOPSIS
    Removes an image attachment from Netbox.

.DESCRIPTION
    Deletes an image attachment from Netbox by ID.

.PARAMETER Id
    The ID of the image attachment to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBImageAttachment -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBImageAttachment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'image-attachments', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Image Attachment')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
