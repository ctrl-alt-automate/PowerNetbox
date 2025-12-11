<#
.SYNOPSIS
    Updates an existing PNTunnel in Netbox V module.

.DESCRIPTION
    Updates an existing PNTunnel in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNTunnel

    Returns all PNTunnel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [ValidateSet('active', 'planned', 'disabled')][string]$Status,
        [ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre')][string]$Encapsulation,
        [uint64]$Group,
        [uint64]$IPSec_Profile,
        [uint64]$Tenant,
        [string]$Description,
        [string]$Comments,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
