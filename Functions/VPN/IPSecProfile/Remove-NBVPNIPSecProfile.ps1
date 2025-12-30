<#
.SYNOPSIS
    Removes a VPN IPSec Profile from Netbox VPN module.

.DESCRIPTION
    Removes a VPN IPSec Profile from Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVVPN IPSec Profile

    Returns all VPN IPSec Profile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVVPN IPSec Profile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process {
        Write-Verbose "Removing VPN IPSec Profile" if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-profiles',$Id)) -Method DELETE -Raw:$Raw } }
}
