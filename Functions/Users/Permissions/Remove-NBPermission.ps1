<#
.SYNOPSIS
    Removes a permission from Netbox.

.DESCRIPTION
    Deletes a permission from Netbox by ID.

.PARAMETER Id
    The ID of the permission to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBPermission -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBPermission {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'permissions', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Permission')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
