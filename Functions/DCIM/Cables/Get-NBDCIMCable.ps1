<#
.SYNOPSIS
    Retrieves cable objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves cable objects from Netbox DCIM module.
    Supports filtering by various parameters including profile (Netbox 4.5+).

.PARAMETER All
    Retrieve all cables (pagination handled automatically).

.PARAMETER PageSize
    Number of results per page (1-1000, default 100).

.PARAMETER Limit
    Maximum number of results to return.

.PARAMETER Offset
    Number of results to skip.

.PARAMETER Id
    Filter by cable ID(s).

.PARAMETER Label
    Filter by cable label.

.PARAMETER Type
    Filter by cable type.

.PARAMETER Status
    Filter by cable status.

.PARAMETER Color
    Filter by cable color.

.PARAMETER Cable_Profile
    Filter by cable profile (Netbox 4.5+ only).

.PARAMETER Device_ID
    Filter by device ID.

.PARAMETER Device
    Filter by device name.

.PARAMETER Rack_Id
    Filter by rack ID.

.PARAMETER Rack
    Filter by rack name.

.PARAMETER Location_ID
    Filter by location ID.

.PARAMETER Location
    Filter by location name.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBDCIMCable

.EXAMPLE
    Get-NBDCIMCable -Cable_Profile '1c4p-4c1p'

.EXAMPLE
    Get-NBDCIMCable -Status 'connected' -Device_ID 5

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

        [switch]$Brief,

        [string[]]$Fields,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Label,

        [string]$Termination_A_Type,

        [uint64]$Termination_A_ID,

        [string]$Termination_B_Type,

        [uint64]$Termination_B_ID,

        [string]$Type,

        [string]$Status,

        [string]$Color,

        [ValidateSet('1c1p', '1c2p', '1c4p', '1c6p', '1c8p', '1c12p', '1c16p',
                     '2c1p', '2c2p', '2c4p', '2c4p-shuffle', '2c6p', '2c8p', '2c12p',
                     '4c1p', '4c2p', '4c4p', '4c4p-shuffle', '4c6p', '4c8p', '8c4p',
                     '1c4p-4c1p', '1c6p-6c1p', '2c4p-8c1p-shuffle')]
        [Alias('Profile')]
        [string]$Cable_Profile,

        [uint64]$Device_ID,

        [string]$Device,

        [uint64]$Rack_Id,

        [string]$Rack,

        [uint64]$Location_ID,

        [string]$Location,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        Write-Verbose "Retrieving DCIM Cable"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cables'))

        # Check for version-specific parameters
        $excludeProfile = Test-NBMinimumVersion -ParameterName 'Cable_Profile' -MinimumVersion '4.5.0' -BoundParameters $PSBoundParameters -FeatureName 'Cable Profiles'

        # Build skip parameters list (always skip Cable_Profile, we'll add it manually as 'profile')
        $skipParams = @('Raw', 'All', 'PageSize', 'Cable_Profile')

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

        # Add Cable_Profile as 'profile' in query params (API uses 'profile')
        if ($PSBoundParameters.ContainsKey('Cable_Profile') -and -not $excludeProfile) {
            $URIComponents.Parameters['profile'] = $Cable_Profile
        }

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
