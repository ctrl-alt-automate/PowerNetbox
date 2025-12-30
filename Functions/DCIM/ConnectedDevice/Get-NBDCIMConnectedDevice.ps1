<#
.SYNOPSIS
    Retrieves Connected Device objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Connected Device objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMConnectedDevice

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMConnectedDevice {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(Mandatory = $true)][string]$Peer_Device,
        [Parameter(Mandatory = $true)][string]$Peer_Interface,
        [switch]$Raw
    )
    process {
        Write-Verbose "Retrieving D CI MC on ne ct ed De vi ce"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','connected-device'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
        InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
    }
}
