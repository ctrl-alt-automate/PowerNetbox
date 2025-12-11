<#
.SYNOPSIS
    Creates a new CIMFrontPort in Netbox D module.

.DESCRIPTION
    Creates a new CIMFrontPort in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMFrontPort

    Returns all CIMFrontPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMFrontPort {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [uint64]$Module,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Label,

        [Parameter(Mandatory = $true)]
        [string]$Type,

        [ValidatePattern('^[0-9a-f]{6}$')]
        [string]$Color,

        [Parameter(Mandatory = $true)]
        [uint64]$Rear_Port,

        [uint64]$Rear_Port_Position,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint16[]]$Tags

    )

    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports'))

    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
}