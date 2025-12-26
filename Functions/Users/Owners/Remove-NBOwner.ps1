<#
.SYNOPSIS
    Removes an owner from Netbox (Netbox 4.5+).

.DESCRIPTION
    Removes an owner from Netbox Users module.
    Owners represent sets of users and/or groups for tracking native object ownership.
    This endpoint is only available in Netbox 4.5 and later.

.PARAMETER Id
    The database ID of the owner to remove (required).

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBOwner -Id 5

.EXAMPLE
    Get-NBOwner -Name "Deprecated Team" | Remove-NBOwner

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBOwner {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'owners', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Owner')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
