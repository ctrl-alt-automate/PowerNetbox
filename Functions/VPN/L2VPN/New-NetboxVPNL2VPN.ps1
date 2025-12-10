function New-NetboxVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,
        [uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,[string]$Description,[string]$Comments,
        [uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
