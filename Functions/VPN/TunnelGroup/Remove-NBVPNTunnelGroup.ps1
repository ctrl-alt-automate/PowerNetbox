<#
.SYNOPSIS
    Removes a VPN TunnelGroup from Netbox VPN module.

.DESCRIPTION
    Removes a VPN TunnelGroup from Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNTunnelGroup

    Deletes a VPN TunnelGroup object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-groups',$Id)) -Method DELETE -Raw:$Raw } }
}
