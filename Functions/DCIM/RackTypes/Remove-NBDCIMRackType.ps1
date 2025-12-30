<#
.SYNOPSIS
    Removes a CIMRackType from Netbox D module.

.DESCRIPTION
    Removes a CIMRackType from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRackType

    Returns all CIMRackType objects.

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
        Write-Verbose "Removing D CI MR ac kT yp e"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
