<#
.SYNOPSIS
    Retrieves jobs from Netbox.

.DESCRIPTION
    Retrieves background jobs from Netbox Core module.

.PARAMETER Id
    Database ID of the job.

.PARAMETER Object_Type
    Filter by object type.

.PARAMETER Object_Id
    Filter by object ID.

.PARAMETER Name
    Filter by job name.

.PARAMETER Status
    Filter by status (pending, scheduled, running, completed, errored, failed).

.PARAMETER User_Id
    Filter by user ID.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBJob

.EXAMPLE
    Get-NBJob -Status "running"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBJob {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,


        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('pending', 'scheduled', 'running', 'completed', 'errored', 'failed')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$User_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Job"
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('core', 'jobs', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('core', 'jobs'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
