<#
.SYNOPSIS
    Removes a irelessLink from Netbox W module.

.DESCRIPTION
    Removes a irelessLink from Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBWirelessLink

    Returns all irelessLink objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-links',$Id)) -Method DELETE -Raw:$Raw } }
}
