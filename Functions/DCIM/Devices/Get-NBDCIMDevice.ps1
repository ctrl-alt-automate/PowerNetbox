<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.
    Supports automatic pagination with the -All switch.

    By default, config_context is excluded from the response for performance.
    Use -IncludeConfigContext to include it when needed.

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

.PARAMETER IncludeConfigContext
    Include config_context in the response. By default, config_context is
    excluded for performance (can be 10-100x faster without it).

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDevice
    Returns the first page of devices (config_context excluded by default).

.EXAMPLE
    Get-NBDCIMDevice -All
    Returns all devices with automatic pagination.

.EXAMPLE
    Get-NBDCIMDevice -Brief
    Returns minimal device representations for dropdowns.

.EXAMPLE
    Get-NBDCIMDevice -Fields 'id','name','status','site.name'
    Returns only the specified fields.

.EXAMPLE
    Get-NBDCIMDevice -IncludeConfigContext
    Returns devices with config_context included.

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

        [switch]$Brief,

        [string[]]$Fields,

        [switch]$IncludeConfigContext,

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

        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'inventory', 'decommissioning', IgnoreCase = $true)]
        [string]$Status,

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
        Write-Verbose "Retrieving DCIM Device"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))

        # Build parameters to pass, excluding config_context by default
        $paramsToPass = @{} + $PSBoundParameters

        # Add exclude=config_context unless IncludeConfigContext is specified
        if (-not $IncludeConfigContext) {
            $paramsToPass['Exclude'] = @('config_context')
        }
        [void]$paramsToPass.Remove('IncludeConfigContext')

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $paramsToPass -SkipParameterByName 'Raw', 'All', 'PageSize'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
