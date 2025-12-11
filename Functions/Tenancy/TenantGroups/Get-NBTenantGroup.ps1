<#
.SYNOPSIS
    Retrieves tenant groups from Netbox.

.DESCRIPTION
    Retrieves tenant groups from the Netbox tenancy module.
    Tenant groups are organizational containers for grouping related tenants.

.PARAMETER Id
    Database ID(s) of the tenant group to retrieve. Accepts pipeline input.

.PARAMETER Name
    Filter by tenant group name.

.PARAMETER Slug
    Filter by tenant group slug.

.PARAMETER Description
    Filter by description.

.PARAMETER Parent_Id
    Filter by parent tenant group ID.

.PARAMETER Query
    General search query.

.PARAMETER Limit
    Maximum number of results to return (1-1000).

.PARAMETER Offset
    Number of results to skip for pagination.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBTenantGroup

    Returns all tenant groups.

.EXAMPLE
    Get-NBTenantGroup -Name "Enterprise*"

    Returns tenant groups matching the name pattern.

.EXAMPLE
    Get-NBTenantGroup -Id 1

    Returns the tenant group with ID 1.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenantgroup/
#>
function Get-NBTenantGroup {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64]$Parent_Id,

        [Alias('q')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenant-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}
