<#
.SYNOPSIS
    Creates a new PAMPrefix in Netbox I module.

.DESCRIPTION
    Creates a new PAMPrefix in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMPrefix

    Returns all PAMPrefix objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function New-NBIPAMPrefix {
    [CmdletBinding(ConfirmImpact = 'low',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Prefix,

        [object]$Status = 'Active',

        [uint64]$Tenant,

        [object]$Role,

        [bool]$IsPool,

        [string]$Description,

        [uint64]$Site,

        [uint64]$VRF,

        [uint64]$VLAN,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    #    $PSBoundParameters.Status = ValidateIPAMChoice -ProvidedValue $Status -PrefixStatus

    <#
    # As of 2018/10/18, this does not appear to be a validated IPAM choice
    if ($null -ne $Role) {
        $PSBoundParameters.Role = ValidateIPAMChoice -ProvidedValue $Role -PrefixRole
    }
    #>

    $segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes'))

    $URIComponents = BuildURIComponents -URISegments $segments -ParametersDictionary $PSBoundParameters

    $URI = BuildNewURI -Segments $URIComponents.Segments

    if ($PSCmdlet.ShouldProcess($Prefix, 'Create new Prefix')) {
        InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
    }
}