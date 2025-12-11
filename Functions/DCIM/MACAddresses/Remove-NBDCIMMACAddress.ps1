function Remove-NBDCIMMACAddress {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete MAC address')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','mac-addresses',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
