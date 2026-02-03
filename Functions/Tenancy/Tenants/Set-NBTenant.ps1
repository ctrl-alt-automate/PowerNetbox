<#
.SYNOPSIS
    Updates an existing tenant in Netbox.

.DESCRIPTION
    Updates an existing tenant in the Netbox tenancy module.
    Supports pipeline input from Get-NBTenant.

.PARAMETER Id
    The database ID of the tenant to update. Accepts pipeline input.

.PARAMETER Name
    The new name of the tenant.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Group
    The database ID of the tenant group.

.PARAMETER Description
    A description of the tenant.

.PARAMETER Comments
    Additional comments about the tenant.

.PARAMETER Tags
    Array of tag IDs to assign.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBTenant -Id 1 -Description "Updated tenant description"

    Updates the description of tenant ID 1.

.EXAMPLE
    Get-NBTenant -Name "Acme Corp" | Set-NBTenant -Group 2

    Moves a tenant to a different group via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenant/
#>
function Set-NBTenant {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Group,

        [string]$Description,

        [string]$Comments,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Tenant"
        foreach ($TenantId in $Id) {

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants', $TenantId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$("ID $TenantId")", 'Update tenant')) {
                InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}
