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

    Returns all IPAM Prefix objects.

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

        [string]$Status,

        [uint64]$Tenant,

        [uint64]$Site,

        [uint64]$VRF,

        [uint64]$VLAN,

        [object]$Role,

        [hashtable]$Custom_Fields,

        [string]$Description,

        [switch]$Is_Pool,

        [uint64]$Owner,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        #        Write-Verbose "Validating enum properties"
        #        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', 0))
        $Method = 'PATCH'
        #
        #        # Value validation
        #        $ModelDefinition = GetModelDefinitionFromURIPath -Segments $Segments -Method $Method
        #        $EnumProperties = GetModelEnumProperties -ModelDefinition $ModelDefinition
        #
        #        foreach ($Property in $EnumProperties.Keys) {
        #            if ($PSBoundParameters.ContainsKey($Property)) {
        #                Write-Verbose "Validating property [$Property] with value [$($PSBoundParameters.$Property)]"
        #                $PSBoundParameters.$Property = ValidateValue -ModelDefinition $ModelDefinition -Property $Property -ProvidedValue $PSBoundParameters.$Property
        #            } else {
        #                Write-Verbose "User did not provide a value for [$Property]"
        #            }
        #        }
        #
        #        Write-Verbose "Finished enum validation"
    }

    process {
        foreach ($PrefixId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $PrefixId))

            Write-Verbose "Obtaining Prefix from ID $PrefixId"

            if ($Force -or $PSCmdlet.ShouldProcess("ID: $PrefixId", 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method -Raw:$Raw
            }
        }
    }
}








