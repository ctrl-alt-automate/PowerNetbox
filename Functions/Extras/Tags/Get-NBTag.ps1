<#
.SYNOPSIS
    Retrieves Tags objects from Netbox Extras module.

.DESCRIPTION
    Retrieves Tags objects from Netbox Extras module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBTag

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBTag {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {

        $Segments = [System.Collections.ArrayList]::new(@('extras', 'tags'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}