function Remove-NBDCIMVirtualDeviceContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete virtual device context')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','virtual-device-contexts',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
