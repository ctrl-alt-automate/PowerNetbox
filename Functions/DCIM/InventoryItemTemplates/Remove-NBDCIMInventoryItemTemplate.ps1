<#
.SYNOPSIS
    Removes a CIMInventoryItemTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMInventoryItemTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInventoryItemTemplate

    Returns all CIMInventoryItemTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMInventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Inventory Item Te mp la te"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
