<#
.SYNOPSIS
    Removes a virtual circuit type from Netbox.

.DESCRIPTION
    Deletes a virtual circuit type from Netbox by ID.

.PARAMETER Id
    The ID of the virtual circuit type to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBVirtualCircuitType -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVirtualCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Virtual Circuit Type"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-types', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Virtual Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
