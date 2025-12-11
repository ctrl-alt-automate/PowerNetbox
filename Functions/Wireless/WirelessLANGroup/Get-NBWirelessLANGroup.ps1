<#
.SYNOPSIS
    Retrieves Wireless LANGroup objects from Netbox Wireless module.

.DESCRIPTION
    Retrieves Wireless LANGroup objects from Netbox Wireless module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBWirelessLANGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBWirelessLANGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][uint64]$Parent_Id,[ValidateRange(1, 1000)]
        [uint16]$Limit,[ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lan-groups',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lan-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}
