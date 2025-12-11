<#
.SYNOPSIS
    Creates a new tenant group in Netbox.

.DESCRIPTION
    Creates a new tenant group in the Netbox tenancy module.
    Tenant groups are organizational containers for grouping related tenants.
    Supports hierarchical nesting via the Parent parameter.

.PARAMETER Name
    The name of the tenant group.

.PARAMETER Slug
    URL-friendly unique identifier. If not provided, will be auto-generated from name.

.PARAMETER Parent
    The database ID of the parent tenant group for hierarchical organization.

.PARAMETER Description
    A description of the tenant group.

.PARAMETER Tags
    Array of tag IDs to assign to this tenant group.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBTenantGroup -Name "Enterprise Customers" -Slug "enterprise-customers"

    Creates a new top-level tenant group.

.EXAMPLE
    New-NBTenantGroup -Name "EMEA" -Parent 1 -Description "European customers"

    Creates a nested tenant group under parent ID 1.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenantgroup/
#>
function New-NBTenantGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        # Auto-generate slug from name if not provided
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }

        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenant-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create tenant group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
