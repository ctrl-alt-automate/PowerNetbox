function New-NetboxVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][uint64]$L2VPN,[Parameter(Mandatory = $true)][string]$Assigned_Object_Type,[Parameter(Mandatory = $true)][uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("L2VPN $L2VPN", 'Create L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
