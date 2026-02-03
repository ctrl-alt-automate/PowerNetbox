
function Get-NBVirtualMachine {
    <#
    .SYNOPSIS
        Obtains virtual machines from Netbox.

    .DESCRIPTION
        Obtains one or more virtual machines based on provided filters.

        By default, config_context is excluded from the response for performance.
        Use -IncludeConfigContext to include it when needed.

    .PARAMETER All
        Automatically fetch all pages of results.

    .PARAMETER PageSize
        Number of items per page when using -All. Default: 100.

    .PARAMETER Brief
        Return a minimal representation of objects (id, url, display, name only).
        Reduces response size by ~90%. Ideal for dropdowns and reference lists.

    .PARAMETER Fields
        Specify which fields to include in the response.
        Supports nested field selection (e.g., 'site.name', 'cluster.name').

    .PARAMETER Omit
        Specify which fields to exclude from the response.
        Requires Netbox 4.5.0 or later.

    .PARAMETER IncludeConfigContext
        Include config_context in the response. By default, config_context is
        excluded for performance (can be 10-100x faster without it).

    .PARAMETER Limit
        Number of results to return per page

    .PARAMETER Offset
        The initial index from which to return the results

    .PARAMETER Query
        A general query used to search for a VM

    .PARAMETER Name
        Name of the VM

    .PARAMETER Id
        Database ID of the VM

    .PARAMETER Status
        Status of the VM

    .PARAMETER Tenant
        String value of tenant

    .PARAMETER Tenant_ID
        Database ID of the tenant.

    .PARAMETER Platform
        String value of the platform

    .PARAMETER Platform_ID
        Database ID of the platform

    .PARAMETER Cluster_Group
        String value of the cluster group.

    .PARAMETER Cluster_Group_Id
        Database ID of the cluster group.

    .PARAMETER Cluster_Type
        String value of the Cluster type.

    .PARAMETER Cluster_Type_Id
        Database ID of the cluster type.

    .PARAMETER Cluster_Id
        Database ID of the cluster.

    .PARAMETER Site
        String value of the site.

    .PARAMETER Site_Id
        Database ID of the site.

    .PARAMETER Role
        String value of the role.

    .PARAMETER Role_Id
        Database ID of the role.

    .PARAMETER Raw
        Return the raw API response instead of extracting the results array.

    .EXAMPLE
        Get-NBVirtualMachine
        Returns VMs with config_context excluded by default.

    .EXAMPLE
        Get-NBVirtualMachine -Brief
        Returns minimal VM representations for dropdowns.

    .EXAMPLE
        Get-NBVirtualMachine -IncludeConfigContext
        Returns VMs with config_context included.

    .EXAMPLE
        Get-NBVirtualMachine -Fields 'id','name','status','site.name'
        Returns only the specified fields.

    .EXAMPLE
        Get-NBVirtualMachine -Omit 'comments','description'
        Returns VMs without comments and description fields (Netbox 4.5+).
#>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [switch]$IncludeConfigContext,

        [Alias('q')]
        [string]$Query,

        [string]$Name,

        [uint64[]]$Id,

        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'decommissioning', IgnoreCase = $true)]
        [string]$Status,

        [string]$Tenant,

        [uint64]$Tenant_ID,

        [string]$Platform,

        [uint64]$Platform_ID,

        [string]$Cluster_Group,

        [uint64]$Cluster_Group_Id,

        [string]$Cluster_Type,

        [uint64]$Cluster_Type_Id,

        [uint64]$Cluster_Id,

        [string]$Site,

        [uint64]$Site_Id,

        [string]$Role,

        [uint64]$Role_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Virtual Machine"
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines'))

        # Build parameters to pass, excluding config_context by default
        $paramsToPass = @{} + $PSBoundParameters

        # Build omit list: start with user-provided fields, add config_context unless explicitly included
        $omitFields = @()
        if ($PSBoundParameters.ContainsKey('Omit')) {
            $omitFields += $Omit
        }
        if (-not $IncludeConfigContext) {
            $omitFields += 'config_context'
        }
        if ($omitFields.Count -gt 0) {
            $paramsToPass['Omit'] = $omitFields | Select-Object -Unique
        }
        [void]$paramsToPass.Remove('IncludeConfigContext')

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $paramsToPass -SkipParameterByName 'Raw', 'All', 'PageSize'

        $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
    }
}
