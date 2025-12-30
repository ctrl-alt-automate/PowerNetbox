<#
.SYNOPSIS
    Retrieves L2VPN objects from Netbox VPN module.

.DESCRIPTION
    Retrieves L2VPN objects from Netbox VPN module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVPNL2VPN

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNL2VPN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][string]$Type,[Parameter(ParameterSetName = 'Query')][uint64]$Tenant_Id,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        Write-Verbose "Retrieving V PN L2V PN"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpns',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}
