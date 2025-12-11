function Get-NBVPNTunnelTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Tunnel_Id,[Parameter(ParameterSetName = 'Query')][string]$Role,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','tunnel-terminations',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}
