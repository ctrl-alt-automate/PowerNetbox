function Remove-NBDCIMPowerOutlet {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power outlet')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-outlets',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
