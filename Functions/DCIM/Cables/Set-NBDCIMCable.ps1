<#
.SYNOPSIS
    Updates an existing cable in Netbox DCIM module.

.DESCRIPTION
    Updates an existing cable in Netbox DCIM module.
    Supports pipeline input for Id parameter.

.PARAMETER Id
    The ID of the cable to update.

.PARAMETER Type
    Cable type.

.PARAMETER Status
    Cable status: connected, planned, decommissioning.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Label
    Cable label.

.PARAMETER Color
    Cable color (hex code without #).

.PARAMETER Length
    Cable length.

.PARAMETER Length_Unit
    Length unit: m, cm, ft, in.

.PARAMETER Description
    Cable description.

.PARAMETER Comments
    Additional comments.

.PARAMETER Tags
    Array of tag names.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Cable_Profile
    Cable profile for path tracing (Netbox 4.5+ only).
    Defines how connectors/lanes on one side map to those on the other side.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBDCIMCable -Id 1 -Label 'Patch-001'

.EXAMPLE
    Set-NBDCIMCable -Id 1 -Cable_Profile '1c4p-4c1p' -Status 'connected'

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Type,

        [string]$Status,

        [uint64]$Tenant,

        [string]$Label,

        [string]$Color,

        [decimal]$Length,

        [string]$Length_Unit,

        [string]$Description,

        [string]$Comments,

        [string[]]$Tags,

        [hashtable]$Custom_Fields,

        [ValidateSet('1c1p', '1c2p', '1c4p', '1c6p', '1c8p', '1c12p', '1c16p',
                     '2c1p', '2c2p', '2c4p', '2c4p-shuffle', '2c6p', '2c8p', '2c12p',
                     '4c1p', '4c2p', '4c4p', '4c4p-shuffle', '4c6p', '4c8p', '8c4p',
                     '1c4p-4c1p', '1c6p-6c1p', '2c4p-8c1p-shuffle')]
        [Alias('Profile')]
        [string]$Cable_Profile,

        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Cable"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cables', $Id))

        # Check for version-specific parameters
        $excludeProfile = Test-NBMinimumVersion -ParameterName 'Cable_Profile' -MinimumVersion '4.5.0' -BoundParameters $PSBoundParameters -FeatureName 'Cable Profiles'

        # Build parameters, excluding version-specific ones if needed
        $skipParams = @('Id', 'Raw', 'Cable_Profile')

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

        # Add Cable_Profile as 'profile' in body (API uses 'profile')
        if ($PSBoundParameters.ContainsKey('Cable_Profile') -and -not $excludeProfile) {
            $URIComponents.Parameters['profile'] = $Cable_Profile
        }

        if ($PSCmdlet.ShouldProcess($Id, 'Update cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
