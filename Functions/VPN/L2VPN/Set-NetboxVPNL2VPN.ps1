function Set-NetboxVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,[string]$Slug,[uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,
        [string]$Description,[string]$Comments,[uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
