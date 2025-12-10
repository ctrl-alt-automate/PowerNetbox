function Set-NetboxVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint32]$SA_Lifetime_Seconds,[uint32]$SA_Lifetime_Data,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-proposals',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
