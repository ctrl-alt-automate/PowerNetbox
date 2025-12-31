<#
.SYNOPSIS
    Removes an API token from Netbox.

.DESCRIPTION
    Deletes an API token from Netbox by ID.

.PARAMETER Id
    The ID of the token to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBToken -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBToken {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Token"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'tokens', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Token')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
