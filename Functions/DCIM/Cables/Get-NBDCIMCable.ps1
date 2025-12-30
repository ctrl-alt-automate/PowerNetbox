<#
.SYNOPSIS
    Retrieves Cables objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Cables objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDDCIM Cable

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMCable {
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

        [string]$Label,

        [string]$Termination_A_Type,

        [uint64]$Termination_A_Id,

        [string]$Termination_B_Type,

        [uint64]$Termination_B_Id,

        [string]$Type,

        [string]$Status,

        [string]$Color,

        [uint64]$Device_Id,

        [string]$Device,

        [uint64]$Rack_Id,

        [string]$Rack,

        [uint64]$Location_Id,

        [string]$Location,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        Write-Verbose "Retrieving DCIM Cable"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cables'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
