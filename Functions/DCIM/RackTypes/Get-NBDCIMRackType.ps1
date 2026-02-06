<#
.SYNOPSIS
    Retrieves Rack Types objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Rack Types objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMRackType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMRackType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,


        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Model,
        [Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][uint64]$Manufacturer_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        Write-Verbose "Retrieving DCIM Rack Type"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-types',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
