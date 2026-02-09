<#
.SYNOPSIS
    Retrieves Module Types objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Module Types objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER All
    Automatically fetch all pages of results. Uses the API's pagination
    to retrieve all items across multiple requests.

.PARAMETER PageSize
    Number of items per page when using -All. Default: 100.
    Range: 1-1000.

.PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

.PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name', 'device_type.model').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.


.EXAMPLE
    Get-NBDCIMModuleType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMModuleType {
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
        [Parameter(ParameterSetName = 'Query')][uint64]$Manufacturer_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Part_Number,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        Write-Verbose "Retrieving DCIM Module Type"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-types',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','module-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
