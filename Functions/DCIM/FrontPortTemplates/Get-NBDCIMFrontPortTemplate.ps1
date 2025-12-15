<#
.SYNOPSIS
    Retrieves Front Port Templates objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Front Port Templates objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMFrontPortTemplate

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMFrontPortTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][uint64]$DeviceType_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$ModuleType_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Type,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','front-port-templates',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','front-port-templates'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}
