<#
.SYNOPSIS
    Updates an existing VPN TunnelGroup in Netbox VPN module.

.DESCRIPTION
    Updates an existing VPN TunnelGroup in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNTunnelGroup

    Updates an existing VPN TunnelGroup object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Slug,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Updating VPN Tunnel Group"
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
