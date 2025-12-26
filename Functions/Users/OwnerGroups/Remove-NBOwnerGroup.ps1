<#
.SYNOPSIS
    Removes an owner group from Netbox (Netbox 4.5+).

.DESCRIPTION
    Removes an owner group from Netbox Users module.
    Owner groups are used to organize owners for object ownership tracking.
    This endpoint is only available in Netbox 4.5 and later.

.PARAMETER Id
    The database ID of the owner group to remove (required).

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBOwnerGroup -Id 5

.EXAMPLE
    Get-NBOwnerGroup -Name "Deprecated Team" | Remove-NBOwnerGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBOwnerGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'owner-groups', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Owner Group')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
