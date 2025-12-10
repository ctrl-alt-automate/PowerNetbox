function New-NetboxVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create tunnel group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
