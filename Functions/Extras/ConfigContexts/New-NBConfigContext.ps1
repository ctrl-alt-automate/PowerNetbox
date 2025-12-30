<#
.SYNOPSIS
    Creates a new config context in Netbox.

.DESCRIPTION
    Creates a new config context in Netbox Extras module.

.PARAMETER Name
    Name of the config context.

.PARAMETER Weight
    Weight for ordering (0-32767).

.PARAMETER Description
    Description of the config context.

.PARAMETER Is_Active
    Whether the config context is active.

.PARAMETER Data
    Configuration data (hashtable or JSON).

.PARAMETER Regions
    Array of region IDs.

.PARAMETER Site_Groups
    Array of site group IDs.

.PARAMETER Sites
    Array of site IDs.

.PARAMETER Locations
    Array of location IDs.

.PARAMETER Device_Types
    Array of device type IDs.

.PARAMETER Roles
    Array of role IDs.

.PARAMETER Platforms
    Array of platform IDs.

.PARAMETER Cluster_Types
    Array of cluster type IDs.

.PARAMETER Cluster_Groups
    Array of cluster group IDs.

.PARAMETER Clusters
    Array of cluster IDs.

.PARAMETER Tenant_Groups
    Array of tenant group IDs.

.PARAMETER Tenants
    Array of tenant IDs.

.PARAMETER Tags
    Array of tag slugs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBConfigContext -Name "NTP Servers" -Data @{ntp_servers = @("10.0.0.1", "10.0.0.2")}

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBConfigContext {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateRange(0, 32767)]
        [uint16]$Weight,

        [string]$Description,

        [bool]$Is_Active,

        [Parameter(Mandatory = $true)]
        $Data,

        [uint64[]]$Regions,

        [uint64[]]$Site_Groups,

        [uint64[]]$Sites,

        [uint64[]]$Locations,

        [uint64[]]$Device_Types,

        [uint64[]]$Roles,

        [uint64[]]$Platforms,

        [uint64[]]$Cluster_Types,

        [uint64[]]$Cluster_Groups,

        [uint64[]]$Clusters,

        [uint64[]]$Tenant_Groups,

        [uint64[]]$Tenants,

        [string[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Config Context"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'config-contexts'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Config Context')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
