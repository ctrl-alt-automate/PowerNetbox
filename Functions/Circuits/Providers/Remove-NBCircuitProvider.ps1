<#
.SYNOPSIS
    Removes a circuit provider from Netbox.

.DESCRIPTION
    Deletes a circuit provider from Netbox by ID.

.PARAMETER Id
    The ID of the provider to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitProvider -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitProvider {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Circuit Provider"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'providers', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Provider')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
