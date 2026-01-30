<#
.SYNOPSIS
    Retrieves Wireless LAN objects from Netbox Wireless module.

.DESCRIPTION
    Retrieves Wireless LAN objects from Netbox Wireless module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBWirelessLAN

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBWirelessLAN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$SSID,[Parameter(ParameterSetName = 'Query')][uint64]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Status,[Parameter(ParameterSetName = 'Query')][uint64]$VLAN_Id,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        Write-Verbose "Retrieving Wireless LAN"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lans',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}
