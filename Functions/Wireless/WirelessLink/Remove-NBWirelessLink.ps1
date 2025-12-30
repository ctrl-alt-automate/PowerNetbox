<#
.SYNOPSIS
    Removes a Wireless Link from Netbox Wireless module.

.DESCRIPTION
    Removes a Wireless Link from Netbox Wireless module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBWWireless Link

    Returns all Wireless Link objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWWireless Link {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process {
        Write-Verbose "Removing Wireless Link" if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-links',$Id)) -Method DELETE -Raw:$Raw } }
}
