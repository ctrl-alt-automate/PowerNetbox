<#
.SYNOPSIS
    Retrieves L2VPNTermination objects from Netbox VPN module.

.DESCRIPTION
    Retrieves L2VPNTermination objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVVPN L2VPNTermination

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNL2VPNTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$L2VPN_Id,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        Write-Verbose "Retrieving V PN L2V PN Te rm in at io n"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpn-terminations',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}
