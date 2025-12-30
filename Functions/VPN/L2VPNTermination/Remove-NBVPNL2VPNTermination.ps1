<#
.SYNOPSIS
    Removes a VPN L2VPNTermination from Netbox VPN module.

.DESCRIPTION
    Removes a VPN L2VPNTermination from Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVVPN L2VPNTermination

    Returns all VPN L2VPNTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVVPN L2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process {
        Write-Verbose "Removing VPN L2VPN  Termination" if ($PSCmdlet.ShouldProcess($Id, 'Delete L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpn-terminations',$Id)) -Method DELETE -Raw:$Raw } }
}
