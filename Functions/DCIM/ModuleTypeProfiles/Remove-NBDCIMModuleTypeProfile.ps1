<#
.SYNOPSIS
    Removes a CIMModuleTypeProfile from Netbox D module.

.DESCRIPTION
    Removes a CIMModuleTypeProfile from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModuleTypeProfile

    Returns all CIMModuleTypeProfile objects.

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
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module type profile')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-type-profiles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
