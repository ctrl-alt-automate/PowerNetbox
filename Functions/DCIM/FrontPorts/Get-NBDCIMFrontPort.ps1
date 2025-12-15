<#
.SYNOPSIS
    Retrieves Front Ports objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Front Ports objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMFrontPort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMFrontPort {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Device,

        [uint64]$Device_Id,

        [string]$Type,

        [switch]$Raw
    )

    process {

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}