<#
.SYNOPSIS
    Removes a VPN IKE Policy from Netbox VPN module.

.DESCRIPTION
    Removes a VPN IKE Policy from Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVVPN IKE Policy

    Returns all VPN IKE Policy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVVPN IKE Policy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process {
        Write-Verbose "Removing VPN IKE Policy" if ($PSCmdlet.ShouldProcess($Id, 'Delete IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-policies',$Id)) -Method DELETE -Raw:$Raw } }
}
