function Remove-NetboxDCIMInventoryItemRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
