function Remove-NBIPAMVLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-groups',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
