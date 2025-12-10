function Set-NetboxVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$Tunnel,[ValidateSet('peer', 'hub', 'spoke')][string]$Role,[string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
