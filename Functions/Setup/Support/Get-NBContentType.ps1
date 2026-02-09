function Get-NBContentType {
<#
    .SYNOPSIS
        Get a content type (object type) definition from Netbox

    .DESCRIPTION
        Wrapper for Get-NBObjectType for backward compatibility.
        Retrieves content type / object type definitions from Netbox.
        Supports Netbox 4.0+ with automatic endpoint detection.

    .PARAMETER Model
        Filter by model name (e.g., 'device', 'site')

    .PARAMETER Id
        The database ID of the content type

    .PARAMETER App_Label
        Filter by app label (e.g., 'dcim', 'ipam')

    .PARAMETER Query
        A standard search query

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Start the search at this index

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NBContentType -App_Label 'dcim'
        Get all DCIM content types

    .EXAMPLE
        PS C:\> Get-NBContentType -Model 'device'
        Get the device content type

    .NOTES
        This function delegates to Get-NBObjectType.
        Backward compatible with Netbox 4.0+
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Model,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$App_Label,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    # Delegate to Get-NBObjectType (the canonical function)
    Get-NBObjectType @PSBoundParameters
}
