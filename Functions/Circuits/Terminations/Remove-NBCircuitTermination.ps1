<#
.SYNOPSIS
    Removes a circuit termination from Netbox.

.DESCRIPTION
    Deletes a circuit termination from Netbox by ID.

.PARAMETER Id
    The ID of the circuit termination to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuitTermination -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Circuit Termination"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-terminations', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
