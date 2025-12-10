function Remove-NetboxVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpns',$Id)) -Method DELETE -Raw:$Raw } }
}
