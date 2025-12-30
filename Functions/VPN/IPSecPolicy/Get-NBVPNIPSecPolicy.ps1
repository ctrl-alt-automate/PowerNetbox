<#
.SYNOPSIS
    Retrieves IPSec Policy objects from Netbox VPN module.

.DESCRIPTION
    Retrieves IPSec Policy objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVVPN IPSec Policy

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNIPSecPolicy {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        Write-Verbose "Retrieving VPN IPSec Policy"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-policies',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}
