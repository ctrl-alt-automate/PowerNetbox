<#
.SYNOPSIS
    Removes a PNTunnelTermination from Netbox V module.

.DESCRIPTION
    Removes a PNTunnelTermination from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNTunnelTermination

    Returns all PNTunnelTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-terminations',$Id)) -Method DELETE -Raw:$Raw } }
}
