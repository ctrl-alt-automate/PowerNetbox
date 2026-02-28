<#
.SYNOPSIS
    Retrieves Connected Device objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves the connected device for a given peer device and interface.
    Returns a single device object (no pagination).

.PARAMETER Peer_Device
    The name of the peer device.

.PARAMETER Peer_Interface
    The name of the peer interface.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMConnectedDevice -Peer_Device "switch01" -Peer_Interface "GigabitEthernet0/1"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMConnectedDevice {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Peer_Device,
        [Parameter(Mandatory = $true)][string]$Peer_Interface,
        [switch]$Raw
    )
    process {
        Write-Verbose "Retrieving DCIM Connected Device"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','connected-device'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
    }
}
