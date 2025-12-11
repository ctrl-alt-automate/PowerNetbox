function Remove-NBDCIMModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','modules',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
