function New-NetboxDCIMLocation {
<#
    .SYNOPSIS
        Create a new location in Netbox

    .DESCRIPTION
        Creates a new location object in Netbox.
        Locations represent physical areas within a site (e.g., floors, rooms, cages).

    .PARAMETER Name
        The name of the location (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER Site
        The site ID where the location exists (required)

    .PARAMETER Parent
        The parent location ID for nested locations

    .PARAMETER Status
        The operational status (planned, staging, active, decommissioning, retired)

    .PARAMETER Tenant
        The tenant ID that owns this location

    .PARAMETER Facility
        The facility identifier

    .PARAMETER Description
        A description of the location

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NetboxDCIMLocation -Name "Server Room" -Slug "server-room" -Site 1

        Creates a new location named "Server Room" at site 1

    .EXAMPLE
        New-NetboxDCIMLocation -Name "Floor 2" -Slug "floor-2" -Site 1 -Status active

        Creates a new active location at site 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [uint64]$Site,

        [uint64]$Parent,

        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'retired')]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Facility,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new location')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
