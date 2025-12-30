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
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [uint64]$Cable,

        [string]$Cable_End,

        [string]$Termination_Type,

        [uint64]$Termination_ID,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        Write-Verbose "Retrieving D CI MC ab le Te rm in at io n"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-terminations'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
