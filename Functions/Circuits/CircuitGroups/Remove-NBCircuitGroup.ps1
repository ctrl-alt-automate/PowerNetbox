<#
.SYNOPSIS
    Removes a circuit group from Netbox.

.DESCRIPTION
    Deletes a circuit group from Netbox by ID.

.PARAMETER Id
    The ID of the circuit group to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitGroup -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Circuit Group"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-groups', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Group')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
