<#
.SYNOPSIS
    Removes a CIMPowerPanel from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerPanel from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerPanel

    Returns all CIMPowerPanel objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerPanel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power panel')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-panels',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
