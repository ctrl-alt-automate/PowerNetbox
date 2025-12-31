<#
.SYNOPSIS
    Removes a CIMPowerOutlet from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerOutlet from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerOutlet

    Returns all CIMPowerOutlet objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerOutlet {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing D CI MP ow er Ou tl et"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power outlet')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-outlets',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
