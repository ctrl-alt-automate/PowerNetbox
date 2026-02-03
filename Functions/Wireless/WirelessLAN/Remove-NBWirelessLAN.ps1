<#
.SYNOPSIS
    Removes a irelessLAN from Netbox W module.

.DESCRIPTION
    Removes a irelessLAN from Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBWirelessLAN

    Deletes a Wireless LAN object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lans',$Id)) -Method DELETE -Raw:$Raw } }
}
