<#
.SYNOPSIS
    Updates an existing PNTunnelTermination in Netbox V module.

.DESCRIPTION
    Updates an existing PNTunnelTermination in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNTunnelTermination

    Returns all PNTunnelTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$Tunnel,[ValidateSet('peer', 'hub', 'spoke')][string]$Role,[string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Updating V PN Tu nn el Te rm in at io n"
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
