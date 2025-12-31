<#
.SYNOPSIS
    Removes a contact role from Netbox.

.DESCRIPTION
    Removes a contact role from the Netbox tenancy module.
    Supports pipeline input from Get-NBContactRole.

.PARAMETER Id
    The database ID(s) of the contact role(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBContactRole -Id 1

    Removes contact role ID 1 (with confirmation prompt).

.EXAMPLE
    Get-NBContactRole | Where-Object { $_.name -like "Test*" } | Remove-NBContactRole -Force

    Removes all contact roles matching a pattern without confirmation.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/contactrole/
#>
function Remove-NBContactRole {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Contact Role"
        foreach ($RoleId in $Id) {
            $CurrentRole = Get-NBContactRole -Id $RoleId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-roles', $CurrentRole.Id))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentRole.Name)", 'Delete contact role')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
