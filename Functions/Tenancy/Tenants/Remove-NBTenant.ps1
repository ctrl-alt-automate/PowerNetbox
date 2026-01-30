<#
.SYNOPSIS
    Removes a tenant from Netbox.

.DESCRIPTION
    Removes a tenant from the Netbox tenancy module.
    Supports pipeline input from Get-NBTenant.

.PARAMETER Id
    The database ID(s) of the tenant(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBTenant -Id 1

    Removes tenant ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBTenant -Id 1, 2, 3 -Force

    Removes multiple tenants without confirmation.

.EXAMPLE
    Get-NBTenant -Group_Id 5 | Remove-NBTenant

    Removes all tenants in a specific group via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenant/
#>
function Remove-NBTenant {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Tenant"
        foreach ($TenantId in $Id) {
            $CurrentTenant = Get-NBTenant -Id $TenantId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants', $CurrentTenant.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentTenant.Name)", 'Delete tenant')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
