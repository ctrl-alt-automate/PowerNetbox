function Remove-NetboxIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-rules',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
