function Remove-NBVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-profiles',$Id)) -Method DELETE -Raw:$Raw } }
}
