function Remove-NetboxWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lans',$Id)) -Method DELETE -Raw:$Raw } }
}
