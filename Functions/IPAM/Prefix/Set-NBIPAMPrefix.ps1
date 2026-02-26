<#
.SYNOPSIS
    Updates an existing IPAM Prefix in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM Prefix in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMPrefix

    Updates an existing IPAM Prefix object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBIPAMPrefix {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Prefix,

        [ValidateSet('active', 'reserved', 'deprecated', 'container', IgnoreCase = $true)]
        [string]$Status,

        [uint64]$Tenant,

        [uint64]$Site,

        [uint64]$VRF,

        [uint64]$VLAN,

        [uint64]$Role,

        [hashtable]$Custom_Fields,

        [string]$Description,

        [bool]$Is_Pool,

        [uint64]$Owner,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($PrefixId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $PrefixId))

            Write-Verbose "Obtaining Prefix from ID $PrefixId"

            if ($Force -or $PSCmdlet.ShouldProcess("ID: $PrefixId", 'Set')) {
                # Transform Site parameter to scope_type and scope_id for new NetBox API
                if ($PSBoundParameters.ContainsKey('Site')) {
                    Write-Verbose "Converting Site parameter to scope_type and scope_id"
                    $PSBoundParameters['scope_type'] = 'dcim.site'
                    $PSBoundParameters['scope_id'] = $PSBoundParameters['Site']
                    $PSBoundParameters.Remove('Site')
                }

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }
}
