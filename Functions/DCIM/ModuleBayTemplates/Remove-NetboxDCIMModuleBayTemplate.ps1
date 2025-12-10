function Remove-NetboxDCIMModuleBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-bay-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
