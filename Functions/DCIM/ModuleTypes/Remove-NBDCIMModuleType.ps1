<#
.SYNOPSIS
    Removes a CIMModuleType from Netbox D module.

.DESCRIPTION
    Removes a CIMModuleType from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModuleType

    Returns all CIMModuleType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModuleType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
