<#
.SYNOPSIS
    Creates a new virtual circuit type in Netbox.

.DESCRIPTION
    Creates a new virtual circuit type in Netbox.

.PARAMETER Name
    Name of the virtual circuit type.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBVirtualCircuitType -Name "EVPN" -Slug "evpn"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVirtualCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Virtual Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
