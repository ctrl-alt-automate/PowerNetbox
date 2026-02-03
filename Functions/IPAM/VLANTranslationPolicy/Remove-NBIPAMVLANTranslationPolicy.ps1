<#
.SYNOPSIS
    Removes a IPAM VLANTranslationPolicy from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM VLANTranslationPolicy from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMVLANTranslationPolicy

    Deletes an IPAM VLAN Translation Policy object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMVLANTranslationPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM VLANT ra ns la ti on Policy"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation policy')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-policies',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
