function Remove-NBIPAMRIR {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete RIR')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','rirs',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
