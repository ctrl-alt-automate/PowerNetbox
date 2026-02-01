<#
.SYNOPSIS
    Removes a DCIM PowerOutletTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM PowerOutletTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerOutletTemplate

    Returns all DCIM PowerOutletTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerOutletTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Power Outlet Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power outlet template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-outlet-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
