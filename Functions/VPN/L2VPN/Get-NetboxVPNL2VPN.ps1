function Get-NetboxVPNL2VPN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param([Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,[Parameter(ParameterSetName = 'Query')][string]$Slug,
        [Parameter(ParameterSetName = 'Query')][string]$Type,[Parameter(ParameterSetName = 'Query')][uint64]$Tenant_Id,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,[Parameter(ParameterSetName = 'Query')][uint16]$Offset,[switch]$Raw)
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','l2vpns',$i)) -Raw:$Raw } }
            default { $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'; InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments -Parameters $u.Parameters) -Raw:$Raw }
        }
    }
}
