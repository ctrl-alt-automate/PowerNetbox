function Remove-NetboxDCIMRearPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rear port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rear-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
