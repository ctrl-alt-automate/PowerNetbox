function Remove-NBDCIMPowerPanel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power panel')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-panels',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
