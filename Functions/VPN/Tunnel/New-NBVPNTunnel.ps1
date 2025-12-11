<#
.SYNOPSIS
    Creates a new PNTunnel in Netbox V module.

.DESCRIPTION
    Creates a new PNTunnel in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNTunnel

    Returns all PNTunnel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet('active', 'planned', 'disabled')][string]$Status,
        [Parameter(Mandatory = $true)][ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre')][string]$Encapsulation,
        [uint64]$Group,
        [uint64]$IPSec_Profile,
        [uint64]$Tenant,
        [uint64]$Tunnel_Id,
        [string]$Description,
        [string]$Comments,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Name, 'Create new VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
