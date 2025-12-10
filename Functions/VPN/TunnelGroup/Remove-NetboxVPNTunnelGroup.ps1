function Remove-NetboxVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-groups',$Id)) -Method DELETE -Raw:$Raw } }
}
