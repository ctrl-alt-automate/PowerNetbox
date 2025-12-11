<#
.SYNOPSIS
    Removes a config context from Netbox.

.DESCRIPTION
    Deletes a config context from Netbox by ID.

.PARAMETER Id
    The ID of the config context to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBConfigContext -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBConfigContext {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'config-contexts', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Config Context')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
