function Remove-NetboxIPAMFHRPGroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-group-assignments',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
