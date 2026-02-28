<#
.SYNOPSIS
    Removes a tenant group from Netbox.

.DESCRIPTION
    Removes a tenant group from the Netbox tenancy module.
    Supports pipeline input from Get-NBTenantGroup.

.PARAMETER Id
    The database ID(s) of the tenant group(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBTenantGroup -Id 1

    Removes tenant group ID 1 (with confirmation prompt).

.EXAMPLE
    Get-NBTenantGroup | Where-Object { $_.tenant_count -eq 0 } | Remove-NBTenantGroup -Force

    Removes all empty tenant groups without confirmation.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/tenantgroup/
#>
function Remove-NBTenantGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Tenant Group"
        foreach ($GroupId in $Id) {

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenant-groups', $GroupId))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("ID $GroupId", 'Delete tenant group')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
