<#
.SYNOPSIS
    Removes a group from Netbox.

.DESCRIPTION
    Deletes a group from Netbox by ID.

.PARAMETER Id
    The ID of the group to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBGroup -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Group"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'groups', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Group')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
