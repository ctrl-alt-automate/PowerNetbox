<#
.SYNOPSIS
    Removes a Wireless LAN from Netbox Wireless module.

.DESCRIPTION
    Removes a Wireless LAN from Netbox Wireless module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBWWireless LAN

    Returns all Wireless LAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process {
        Write-Verbose "Removing Wireless LAN" if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lans',$Id)) -Method DELETE -Raw:$Raw } }
}
