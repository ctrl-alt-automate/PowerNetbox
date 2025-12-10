function Set-NetboxVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$L2VPN,[string]$Assigned_Object_Type,[uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
