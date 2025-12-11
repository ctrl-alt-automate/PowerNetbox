<#
.SYNOPSIS
    Retrieves Wireless Link objects from Netbox Wireless module.

.DESCRIPTION
    Retrieves Wireless Link objects from Netbox Wireless module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBWirelessLink

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBWirelessLink {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$SSID,[Parameter(ParameterSetName = 'Query')][string]$Status,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-links',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('wireless','wireless-links')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}
