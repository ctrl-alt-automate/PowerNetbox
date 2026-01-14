<#
.SYNOPSIS
    Updates an existing tenant group in Netbox.

.DESCRIPTION
    Updates an existing tenant group in the Netbox tenancy module.
    Supports pipeline input from Get-NBTenantGroup.

.PARAMETER Id
    The database ID of the tenant group to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the tenant group.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Parent
    The database ID of the parent tenant group.

.PARAMETER Description
    A description of the tenant group.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBTenantGroup -Id 1 -Description "Updated description"

    Updates the description of tenant group ID 1.

.EXAMPLE
    Get-NBTenantGroup -Name "legacy" | Set-NBTenantGroup -Parent 2

    Moves a tenant group under a new parent via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenantgroup/
#>
function Set-NBTenantGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Tenant Group"
        foreach ($GroupId in $Id) {
            $CurrentGroup = Get-NBTenantGroup -Id $GroupId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenant-groups', $CurrentGroup.Id))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentGroup.Name)", 'Update tenant group')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}
