<#
.SYNOPSIS
    Retrieves Branch Event objects from the Netbox Branching plugin.

.DESCRIPTION
    Retrieves branch event logs from the Netbox Branching plugin.
    Events track operations like sync, merge, and revert.

.PARAMETER Id
    The ID of a specific branch event to retrieve.

.PARAMETER Branch_Id
    Filter events by branch ID.

.PARAMETER All
    Retrieve all events with automatic pagination.

.PARAMETER PageSize
    Number of items per page when using -All. Default: 100.

.PARAMETER Limit
    Maximum number of results to return.

.PARAMETER Offset
    Number of results to skip.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

.PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name', 'device_type.model').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

.OUTPUTS
    [PSCustomObject] Branch event object(s).

.EXAMPLE
    Get-NBBranchEvent
    Get all branch events.

.EXAMPLE
    Get-NBBranchEvent -Branch_Id 5
    Get all events for branch ID 5.

.EXAMPLE
    Get-NBBranchEvent -Id 10
    Get specific event by ID.

.LINK
    Get-NBBranch
#>
function Get-NBBranchEvent {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Branch_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Branch Event"
        CheckNetboxIsConnected

        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($EventId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('plugins', 'branching', 'branch-events', $EventId))

                    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('plugins', 'branching', 'branch-events'))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
