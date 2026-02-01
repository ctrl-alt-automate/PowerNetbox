<#
.SYNOPSIS
    Creates a new VPN IPSecPolicy in Netbox VPN module.

.DESCRIPTION
    Creates a new VPN IPSecPolicy in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNIPSecPolicy

    Returns all VPN IPSecPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[uint64[]]$Proposals,[bool]$Pfs_Group,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Creating VPN IPSec Policy"
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
