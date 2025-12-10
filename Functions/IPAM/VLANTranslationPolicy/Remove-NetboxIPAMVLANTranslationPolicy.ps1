function Remove-NetboxIPAMVLANTranslationPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation policy')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-policies',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
