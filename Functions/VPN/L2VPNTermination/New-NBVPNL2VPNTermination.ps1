<#
.SYNOPSIS
    Creates a new VPN L2VPNTermination in Netbox VPN module.

.DESCRIPTION
    Creates a new VPN L2VPNTermination in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVVPN L2VPNTermination

    Returns all VPN L2VPNTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVVPN L2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][uint64]$L2VPN,[Parameter(Mandatory = $true)][string]$Assigned_Object_Type,[Parameter(Mandatory = $true)][uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Creating V PN L2V PN Te rm in at io n"
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("L2VPN $L2VPN", 'Create L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
