function Remove-NetboxDCIMPowerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
