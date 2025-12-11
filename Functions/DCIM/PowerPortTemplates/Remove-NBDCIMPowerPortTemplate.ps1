<#
.SYNOPSIS
    Removes a CIMPowerPortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerPortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerPortTemplate

    Returns all CIMPowerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
