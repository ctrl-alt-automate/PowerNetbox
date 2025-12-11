<#
.SYNOPSIS
    Retrieves custom fields from Netbox.

.DESCRIPTION
    Retrieves custom fields from Netbox Extras module.

.PARAMETER Id
    Database ID of the custom field.

.PARAMETER Name
    Filter by name.

.PARAMETER Type
    Filter by field type.

.PARAMETER Content_Types
    Filter by content types.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBCustomField

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCustomField {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Content_Types,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}
