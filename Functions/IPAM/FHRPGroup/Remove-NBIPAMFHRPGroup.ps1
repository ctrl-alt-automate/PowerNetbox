function Remove-NBIPAMFHRPGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete FHRP group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-groups',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
