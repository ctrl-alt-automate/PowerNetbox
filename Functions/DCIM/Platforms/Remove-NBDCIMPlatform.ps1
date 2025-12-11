function Remove-NBDCIMPlatform {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete platform')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','platforms',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
