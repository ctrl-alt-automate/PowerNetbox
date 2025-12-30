<#
.SYNOPSIS
    Removes a PAMVLANTranslationPolicy from Netbox I module.

.DESCRIPTION
    Removes a PAMVLANTranslationPolicy from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMVLANTranslationPolicy

    Returns all PAMVLANTranslationPolicy objects.

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
        Write-Verbose "Removing I PA MV LA NT ra ns la ti on Po li cy"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation policy')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-policies',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
