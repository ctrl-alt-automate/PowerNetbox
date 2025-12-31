<#
.SYNOPSIS
    Removes a webhook from Netbox.

.DESCRIPTION
    Deletes a webhook from Netbox by ID.

.PARAMETER Id
    The ID of the webhook to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBWebhook -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWebhook {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Webhook"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'webhooks', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Webhook')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
