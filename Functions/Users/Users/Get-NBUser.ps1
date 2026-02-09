<#
.SYNOPSIS
    Retrieves users from Netbox.

.DESCRIPTION
    Retrieves users from Netbox Users module.

.PARAMETER Id
    Database ID of the user.

.PARAMETER Username
    Filter by username.

.PARAMETER First_Name
    Filter by first name.

.PARAMETER Last_Name
    Filter by last name.

.PARAMETER Email
    Filter by email.

.PARAMETER Is_Staff
    Filter by staff status.

.PARAMETER Is_Active
    Filter by active status.

.PARAMETER Is_Superuser
    Filter by superuser status.

.PARAMETER Group_Id
    Filter by group ID.

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER All
    Automatically fetch all pages of results. Uses the API's pagination
    to retrieve all items across multiple requests.

.PARAMETER PageSize
    Number of items per page when using -All. Default: 100.
    Range: 1-1000.

.PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

.PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name', 'device_type.model').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.


.EXAMPLE
    Get-NBUser

.EXAMPLE
    Get-NBUser -Username "admin"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBUser {
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
        [string]$Username,

        [Parameter(ParameterSetName = 'Query')]
        [string]$First_Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Last_Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Email,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Staff,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Active,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Superuser,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving User"
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('users', 'users', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('users', 'users'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
