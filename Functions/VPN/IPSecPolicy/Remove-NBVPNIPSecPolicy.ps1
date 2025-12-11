function Remove-NBVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-policies',$Id)) -Method DELETE -Raw:$Raw } }
}
