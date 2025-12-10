function Remove-NetboxDCIMDeviceBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bay-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
