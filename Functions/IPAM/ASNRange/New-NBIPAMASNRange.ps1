function New-NBIPAMASNRange {
<#
    .SYNOPSIS
        Create a new ASN range in Netbox

    .DESCRIPTION
        Creates a new ASN range object in Netbox.

    .PARAMETER Name
        The name of the ASN range (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID (required)

    .PARAMETER Start
        The starting ASN number (required)

    .PARAMETER End
        The ending ASN number (required)

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Description
        A description of the ASN range

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NBIPAMASNRange -Name "Private" -Slug "private" -RIR 1 -Start 64512 -End 65534

        Creates a private ASN range
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [uint64]$RIR,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4294967295)]
        [uint64]$Start,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4294967295)]
        [uint64]$End,

        [uint64]$Tenant,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new ASN range')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
