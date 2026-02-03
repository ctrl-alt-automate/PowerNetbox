<#
.SYNOPSIS
    Retrieves Change Diff objects from the Netbox Branching plugin.

.DESCRIPTION
    Retrieves change diffs that show what modifications exist in a branch.
    Each diff shows the original data, modified data, and any conflicts.

.PARAMETER Id
    The ID of a specific change diff to retrieve.

.PARAMETER Branch_Id
    Filter changes by branch ID.

.PARAMETER Object_Type
    Filter by object type (e.g., 'dcim.device', 'ipam.ipaddress').

.PARAMETER Action
    Filter by action type: create, update, delete.

.PARAMETER All
    Retrieve all changes with automatic pagination.

.PARAMETER PageSize
    Number of items per page when using -All. Default: 100.

.PARAMETER Limit
    Maximum number of results to return.

.PARAMETER Offset
    Number of results to skip.

.PARAMETER Raw
    Return the raw API response.

.OUTPUTS
    [PSCustomObject] Change diff object(s).

.EXAMPLE
    Get-NBChangeDiff -Branch_Id 1
    Get all changes in branch ID 1.

.EXAMPLE
    Get-NBChangeDiff -Branch_Id 1 -Action "create"
    Get only created objects in branch.

.EXAMPLE
    Get-NBChangeDiff -Branch_Id 1 | Where-Object { $_.conflicts }
    Get conflicting changes in branch.

.LINK
    Get-NBBranch
    Merge-NBBranch
#>
function Get-NBChangeDiff {
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

        [Parameter(ParameterSetName = 'Query')]
        [string]$Object_Type,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('create', 'update', 'delete')]
        [string]$Action,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Change Diff"
        CheckNetboxIsConnected

        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($ChangeId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('plugins', 'branching', 'changes', $ChangeId))

                    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('plugins', 'branching', 'changes'))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
