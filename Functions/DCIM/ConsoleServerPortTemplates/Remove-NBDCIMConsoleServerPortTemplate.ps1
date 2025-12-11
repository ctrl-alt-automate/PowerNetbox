function Remove-NBDCIMConsoleServerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console server port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-server-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
