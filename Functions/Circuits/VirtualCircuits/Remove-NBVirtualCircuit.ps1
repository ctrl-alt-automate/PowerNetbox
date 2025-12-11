<#
.SYNOPSIS
    Removes a virtual circuit from Netbox.

.DESCRIPTION
    Deletes a virtual circuit from Netbox by ID.

.PARAMETER Id
    The ID of the virtual circuit to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBVirtualCircuit -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVirtualCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuits', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Virtual Circuit')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
