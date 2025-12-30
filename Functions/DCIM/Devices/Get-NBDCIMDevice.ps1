<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.
    Supports automatic pagination with the -All switch.

.PARAMETER All
    Automatically fetch all pages of results. Uses the API's pagination
    to retrieve all items across multiple requests.

.PARAMETER PageSize
    Number of items per page when using -All. Default: 100.
    Range: 1-1000.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDevice
    Returns the first page of devices (default limit).

.EXAMPLE
    Get-NBDCIMDevice -All
    Returns all devices with automatic pagination.

.EXAMPLE
    Get-NBDCIMDevice -All -PageSize 200 -Verbose
    Returns all devices with 200 items per request, showing progress.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDevice {
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

        [string]$Query,

        [string]$Name,

        [uint64]$Manufacturer_Id,

        [string]$Manufacturer,

        [uint64]$Device_Type_Id,

        [uint64]$Role_Id,

        [string]$Role,

        [uint64]$Tenant_Id,

        [string]$Tenant,

        [uint64]$Platform_Id,

        [string]$Platform,

        [string]$Asset_Tag,

        [uint64]$Site_Id,

        [string]$Site,

        [uint64]$Rack_Group_Id,

        [uint64]$Rack_Id,

        [uint64]$Cluster_Id,

        [uint64]$Model,

        [object]$Status,

        [bool]$Is_Full_Depth,

        [bool]$Is_Console_Server,

        [bool]$Is_PDU,

        [bool]$Is_Network_Device,

        [string]$MAC_Address,

        [bool]$Has_Primary_IP,

        [uint64]$Virtual_Chassis_Id,

        [uint16]$Position,

        [string]$Serial,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        Write-Verbose "Retrieving D CI MD ev ic e"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
