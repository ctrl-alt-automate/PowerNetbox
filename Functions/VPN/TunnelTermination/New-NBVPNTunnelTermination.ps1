<#
.SYNOPSIS
    Creates a new PNTunnelTermination in Netbox V module.

.DESCRIPTION
    Creates a new PNTunnelTermination in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNTunnelTermination

    Returns all PNTunnelTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][uint64]$Tunnel,[Parameter(Mandatory = $true)][ValidateSet('peer', 'hub', 'spoke')][string]$Role,
        [string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Creating V PN Tu nn el Te rm in at io n"
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Tunnel $Tunnel", 'Create tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
