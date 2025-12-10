function New-NetboxVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][uint64]$Tunnel,[Parameter(Mandatory = $true)][ValidateSet('peer', 'hub', 'spoke')][string]$Role,
        [string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Tunnel $Tunnel", 'Create tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
