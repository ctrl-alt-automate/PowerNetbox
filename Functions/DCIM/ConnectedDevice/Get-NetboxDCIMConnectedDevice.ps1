function Get-NetboxDCIMConnectedDevice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Peer_Device,
        [Parameter(Mandatory = $true)][string]$Peer_Interface,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','connected-device'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
    }
}
