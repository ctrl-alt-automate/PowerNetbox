<#
.SYNOPSIS
    Removes a PNL2VPNTermination from Netbox V module.

.DESCRIPTION
    Removes a PNL2VPNTermination from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNL2VPNTermination

    Returns all PNL2VPNTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpn-terminations',$Id)) -Method DELETE -Raw:$Raw } }
}
