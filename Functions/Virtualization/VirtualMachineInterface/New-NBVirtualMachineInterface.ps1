<#
.SYNOPSIS
    Creates a new irtualMachineInterface in Netbox V module.

.DESCRIPTION
    Creates a new irtualMachineInterface in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualMachineInterface

    Returns all irtualMachineInterface objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function New-NBVirtualMachineInterface {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint64]$Virtual_Machine,

        [boolean]$Enabled = $true,

        [string]$MAC_Address,

        [uint16]$MTU,

        [string]$Description,

        [switch]$Raw
    )

    $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces'))

    $PSBoundParameters.Enabled = $Enabled

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

    $uri = BuildNewURI -Segments $URIComponents.Segments

    InvokeNetboxRequest -URI $uri -Method POST -Body $URIComponents.Parameters
}