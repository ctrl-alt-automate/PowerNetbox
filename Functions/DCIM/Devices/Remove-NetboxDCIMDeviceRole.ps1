function Remove-NetboxDCIMDeviceRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
