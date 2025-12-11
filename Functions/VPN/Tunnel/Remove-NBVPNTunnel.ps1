<#
.SYNOPSIS
    Removes a PNTunnel from Netbox V module.

.DESCRIPTION
    Removes a PNTunnel from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNTunnel

    Returns all PNTunnel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $Id))
        $URI = BuildNewURI -Segments $Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
