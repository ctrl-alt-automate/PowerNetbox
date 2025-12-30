<#
.SYNOPSIS
    Removes a DCIM Power OutletTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Power OutletTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Power OutletTemplate

    Returns all DCIM Power OutletTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM Power OutletTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Power Outlet Te mp la te"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power outlet template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-outlet-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
