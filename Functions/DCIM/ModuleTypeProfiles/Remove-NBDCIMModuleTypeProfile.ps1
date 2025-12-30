<#
.SYNOPSIS
    Removes a DCIM Module Type Profile from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Module Type Profile from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Module Type Profile

    Returns all DCIM Module Type Profile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModuleTypeProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM ModuleT yp eP ro fi le"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module type profile')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-type-profiles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
