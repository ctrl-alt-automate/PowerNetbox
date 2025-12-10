function Get-NetboxVPNTunnel {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [Parameter(ParameterSetName = 'Query')][string]$Status,
        [Parameter(ParameterSetName = 'Query')][uint64]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Encapsulation,
        [Parameter(ParameterSetName = 'Query')][uint16]$Limit,
        [Parameter(ParameterSetName = 'Query')][uint16]$Offset,
        [switch]$Raw
    )
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($TunnelId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $TunnelId))
                    $URI = BuildNewURI -Segments $Segments
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}
