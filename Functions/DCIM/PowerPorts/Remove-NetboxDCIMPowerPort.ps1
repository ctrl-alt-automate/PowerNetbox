function Remove-NetboxDCIMPowerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-ports',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
