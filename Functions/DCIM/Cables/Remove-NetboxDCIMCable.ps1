function Remove-NetboxDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','cables',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
