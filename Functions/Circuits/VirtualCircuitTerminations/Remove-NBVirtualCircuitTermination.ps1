<#
.SYNOPSIS
    Removes a virtual circuit termination from Netbox.

.DESCRIPTION
    Deletes a virtual circuit termination from Netbox by ID.

.PARAMETER Id
    The ID of the termination to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBVirtualCircuitTermination -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVirtualCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Virtual Circuit Termination"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-terminations', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Virtual Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
