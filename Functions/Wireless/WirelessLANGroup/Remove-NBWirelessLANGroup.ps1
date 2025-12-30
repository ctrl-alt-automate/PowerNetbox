<#
.SYNOPSIS
    Removes a Wireless LANGroup from Netbox Wireless module.

.DESCRIPTION
    Removes a Wireless LANGroup from Netbox Wireless module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBWWireless LANGroup

    Returns all Wireless LANGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWWireless LANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process {
        Write-Verbose "Removing Wireless LAN Group" if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lan-groups',$Id)) -Method DELETE -Raw:$Raw } }
}
