<#
.SYNOPSIS
    Removes a DCIM RackReservation from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM RackReservation from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRackReservation

    Returns all DCIM RackReservation objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRackReservation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM RackR es er va ti on"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack reservation')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-reservations',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
