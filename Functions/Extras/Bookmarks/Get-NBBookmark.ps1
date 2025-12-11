<#
.SYNOPSIS
    Retrieves bookmarks from Netbox.

.DESCRIPTION
    Retrieves bookmarks from Netbox Extras module.

.PARAMETER Id
    Database ID of the bookmark.

.PARAMETER Object_Type
    Filter by object type.

.PARAMETER Object_Id
    Filter by object ID.

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBBookmark

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBBookmark {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

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
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}
