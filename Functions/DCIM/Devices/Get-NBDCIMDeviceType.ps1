<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDeviceType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDeviceType {
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

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Manufacturer,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Manufacturer_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Model,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Part_Number,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$U_Height,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Full_Depth,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Console_Server,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_PDU,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Network_Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Subdevice_Role,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        Write-Verbose "Retrieving DCIM Device Type"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'device-types', $i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
