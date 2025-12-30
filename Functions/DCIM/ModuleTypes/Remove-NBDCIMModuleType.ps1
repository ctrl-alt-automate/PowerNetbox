<#
.SYNOPSIS
    Removes a DCIM Module Type from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Module Type from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Module Type

    Returns all DCIM Module Type objects.

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
        Write-Verbose "Removing DCIM ModuleT yp e"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
