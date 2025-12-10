function Remove-NetboxDCIMConsoleServerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console server port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-server-ports',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
