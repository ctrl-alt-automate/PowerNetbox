<#
.SYNOPSIS
    Removes a CIMInventoryItemRole from Netbox D module.

.DESCRIPTION
    Removes a CIMInventoryItemRole from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInventoryItemRole

    Returns all CIMInventoryItemRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMInventoryItemRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Inventory Item Ro le"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
