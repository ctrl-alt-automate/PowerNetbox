function Remove-NBDCIMConsolePortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
