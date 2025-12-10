function Remove-NetboxDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-feeds',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
