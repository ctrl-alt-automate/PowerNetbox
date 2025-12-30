function Set-NBIPAMASNRange {
<#
    .SYNOPSIS
        Update an ASN range in Netbox

    .DESCRIPTION
        Updates an existing ASN range object in Netbox.

    .PARAMETER Id
        The ID of the ASN range to update (required)

    .PARAMETER Name
        The name of the ASN range

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID

    .PARAMETER Start
        The starting ASN number

    .PARAMETER End
        The ending ASN number

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Description
        A description of the ASN range

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NBIIPAM ASNRange -Id 1 -Description "Updated description"

        Updates the description of ASN range 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$RIR,

        [ValidateRange(1, 4294967295)]
        [uint64]$Start,

        [ValidateRange(1, 4294967295)]
        [uint64]$End,

        [uint64]$Tenant,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating IPAM ASN Ra ng e"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update ASN range')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
