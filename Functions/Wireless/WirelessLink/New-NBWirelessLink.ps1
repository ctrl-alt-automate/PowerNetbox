function New-NBWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param([Parameter(Mandatory = $true)][uint64]$Interface_A,[Parameter(Mandatory = $true)][uint64]$Interface_B,
        [string]$SSID,[string]$Status,[uint64]$Tenant,[string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,
        [string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-links')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Interface_A to $Interface_B", 'Create wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
