function Remove-NetboxDCIMVirtualChassis {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete virtual chassis')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','virtual-chassis',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
