<#
.SYNOPSIS
    Retrieves Cable Terminations objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Cable Terminations objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMCableTermination

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMCableTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,
        [string[]]$Omit,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Cable,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Cable_End,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Termination_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Termination_ID,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        Write-Verbose "Retrieving DCIM Cable Termination"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-terminations'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
