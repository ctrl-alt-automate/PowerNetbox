<#
.SYNOPSIS
    Removes a circuit from Netbox.

.DESCRIPTION
    Deletes a circuit from Netbox by ID.

.PARAMETER Id
    The ID of the circuit to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBCircuit -Id 1

.EXAMPLE
    Get-NBCircuit -Id 1 | Remove-NBCircuit

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Circuit"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Circuit')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
