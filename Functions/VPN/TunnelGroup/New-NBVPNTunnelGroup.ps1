<#
.SYNOPSIS
    Creates a new VPN TunnelGroup in Netbox VPN module.

.DESCRIPTION
    Creates a new VPN TunnelGroup in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNTunnelGroup

    Returns all VPN TunnelGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Creating VPN Tunnel Group"
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
