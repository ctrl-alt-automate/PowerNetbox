<#
.SYNOPSIS
    Removes a DCIM InventoryItemTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM InventoryItemTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM InventoryItemTemplate

    Returns all DCIM InventoryItemTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM InventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Inventory Item Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
