<#
.SYNOPSIS
    Retrieves Branch objects from the Netbox Branching plugin.

.DESCRIPTION
    Retrieves one or more branches from the Netbox Branching plugin.
    Supports filtering by ID, name, status, and owner.

.PARAMETER Id
    The ID of a specific branch to retrieve.

.PARAMETER Name
    Filter branches by name.

.PARAMETER Status
    Filter branches by status. Valid values: ready, merged, conflict.

.PARAMETER Owner
    Filter branches by owner username.

.PARAMETER Query
    Search query string.

.PARAMETER All
    Retrieve all branches with automatic pagination.

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
    [PSCustomObject] Branch object(s).

.EXAMPLE
    Get-NBBranch
    Get all branches.

.EXAMPLE
    Get-NBBranch -Id 5
    Get branch with ID 5.

.EXAMPLE
    Get-NBBranch -Name "feature/datacenter"
    Get branch by name.

.EXAMPLE
    Get-NBBranch -Status "ready"
    Get all ready branches.

.LINK
    New-NBBranch
    Set-NBBranch
    Remove-NBBranch
#>
function Get-NBBranch {
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
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('ready', 'merged', 'conflict')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Owner,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Branch"
        CheckNetboxIsConnected

        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($BranchId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('plugins', 'branching', 'branches', $BranchId))

                    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('plugins', 'branching', 'branches'))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
