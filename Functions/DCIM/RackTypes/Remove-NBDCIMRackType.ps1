<#
.SYNOPSIS
    Removes a DCIM RackType from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM RackType from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM RackType

    Returns all DCIM RackType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRackType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM RackT yp e"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
