function Remove-NetboxDCIMInventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
