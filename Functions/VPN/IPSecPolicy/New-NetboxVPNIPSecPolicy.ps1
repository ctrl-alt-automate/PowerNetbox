function New-NetboxVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[uint64[]]$Proposals,[bool]$Pfs_Group,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-policies')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
