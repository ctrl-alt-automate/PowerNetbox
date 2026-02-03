<#
.SYNOPSIS
    Removes a VPN L2VPN from Netbox VPN module.

.DESCRIPTION
    Removes a VPN L2VPN from Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNL2VPN

    Deletes a VPN L2VPN object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpns',$Id)) -Method DELETE -Raw:$Raw } }
}
