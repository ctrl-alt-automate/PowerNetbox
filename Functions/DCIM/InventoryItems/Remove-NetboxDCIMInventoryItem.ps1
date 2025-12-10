function Remove-NetboxDCIMInventoryItem {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-items',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
