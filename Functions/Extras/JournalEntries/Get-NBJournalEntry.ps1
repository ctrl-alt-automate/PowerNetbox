<#
.SYNOPSIS
    Retrieves journal entries from Netbox.

.DESCRIPTION
    Retrieves journal entries from Netbox Extras module.

.PARAMETER Id
    Database ID of the journal entry.

.PARAMETER Assigned_Object_Type
    Filter by assigned object type.

.PARAMETER Assigned_Object_Id
    Filter by assigned object ID.

.PARAMETER Created_By
    Filter by creator user ID.

.PARAMETER Kind
    Filter by kind (info, success, warning, danger).

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBJournalEntry

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBJournalEntry {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Assigned_Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Assigned_Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Created_By,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('info', 'success', 'warning', 'danger')]
        [string]$Kind,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Journal Entry"
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
