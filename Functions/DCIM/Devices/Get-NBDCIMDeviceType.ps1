<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDDCIM Device Type

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDeviceType {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Query,

        [string]$Slug,

        [string]$Manufacturer,

        [uint64]$Manufacturer_Id,

        [string]$Model,

        [string]$Part_Number,

        [uint16]$U_Height,

        [bool]$Is_Full_Depth,

        [bool]$Is_Console_Server,

        [bool]$Is_PDU,

        [bool]$Is_Network_Device,

        [uint16]$Subdevice_Role,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving DCIM DeviceT yp e"
        #endregion Parameters

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-types'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
