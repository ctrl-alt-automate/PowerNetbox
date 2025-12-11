<#
.SYNOPSIS
    Removes a PNIKEPolicy from Netbox V module.

.DESCRIPTION
    Removes a PNIKEPolicy from Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVPNIKEPolicy

    Returns all PNIKEPolicy objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ike-policies',$Id)) -Method DELETE -Raw:$Raw } }
}
