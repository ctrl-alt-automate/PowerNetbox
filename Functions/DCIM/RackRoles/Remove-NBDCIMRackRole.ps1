function Remove-NBDCIMRackRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rack-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
