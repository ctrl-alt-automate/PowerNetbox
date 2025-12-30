<#
.SYNOPSIS
    Removes a user from Netbox.

.DESCRIPTION
    Deletes a user from Netbox by ID.

.PARAMETER Id
    The ID of the user to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBUser -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing User"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'users', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete User')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
