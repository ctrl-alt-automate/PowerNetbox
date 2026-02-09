<#
.SYNOPSIS
    Retrieves Interfaces objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Interfaces objects from Netbox DCIM module.

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER All
    Automatically fetch all pages of results. Uses the API's pagination
    to retrieve all items across multiple requests.

.PARAMETER PageSize
    Number of items per page when using -All. Default: 100.
    Range: 1-1000.

.PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

.PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name', 'device_type.model').


.EXAMPLE
    Get-NBDCIMInterface

.EXAMPLE
    Get-NBDCIMInterface -Omit 'description'
    Returns interfaces without the description field (Netbox 4.5+).

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMInterface {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,


        [string[]]$Omit,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$MTU,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$MGMT_Only,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Device_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('virtual', 'bridge', 'lag', '100base-tx', '1000base-t', '2.5gbase-t', '5gbase-t', '10gbase-t', '10gbase-cx4', '1000base-x-gbic', '1000base-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '200gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cpak', '100gbase-x-qsfp28', '200gbase-x-qsfp56', '400gbase-x-qsfpdd', '400gbase-x-osfp', '1000base-kx', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.15.1', 'other-wireless', 'gsm', 'cdma', 'lte', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '64gfc-qsfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', 'epon', '10g-epon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$LAG_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$MAC_Address,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving DCIM Interface"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'interfaces', $i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
