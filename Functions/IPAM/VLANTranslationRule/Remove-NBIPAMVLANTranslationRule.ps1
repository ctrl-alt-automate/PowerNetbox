<#
.SYNOPSIS
    Removes a IPAM VLANTranslationRule from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM VLANTranslationRule from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIIPAM VLANTranslationRule

    Returns all IPAM VLANTranslationRule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIIPAM VLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM VLANT ra ns la ti on Ru le"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-rules',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
