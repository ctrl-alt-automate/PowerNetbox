function New-NetboxVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[string]$Authentication_Method,[string]$Encryption_Algorithm,
        [string]$Authentication_Algorithm,[uint16]$Group,[uint32]$SA_Lifetime,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-proposals')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create IKE proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
