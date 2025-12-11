<#
.SYNOPSIS
    Retrieves object changes from Netbox.

.DESCRIPTION
    Retrieves object change log entries from Netbox Core module.

.PARAMETER Id
    Database ID of the object change.

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER User_Name
    Filter by username.

.PARAMETER Changed_Object_Type
    Filter by changed object type.

.PARAMETER Changed_Object_Id
    Filter by changed object ID.

.PARAMETER Action
    Filter by action (create, update, delete).

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBObjectChange

.EXAMPLE
    Get-NBObjectChange -Action "create" -Limit 50

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBObjectChange {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$User_Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Changed_Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Changed_Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('create', 'update', 'delete')]
        [string]$Action,

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
                    $Segments = [System.Collections.ArrayList]::new(@('core', 'object-changes', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('core', 'object-changes'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}
