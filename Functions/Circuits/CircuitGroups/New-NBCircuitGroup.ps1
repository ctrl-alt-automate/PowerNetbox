<#
.SYNOPSIS
    Creates a new circuit group in Netbox.

.DESCRIPTION
    Creates a new circuit group in Netbox.

.PARAMETER Name
    Name of the circuit group.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Description
    Description.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitGroup -Name "WAN Links" -Slug "wan-links"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64]$Tenant,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Circuit Group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
