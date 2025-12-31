<#
.SYNOPSIS
    Retrieves Address objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves Address objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMAddress

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMAddress {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(ParameterSetName = 'Query',
            Position = 0)]
        [string]$Address,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Parent,

        [Parameter(ParameterSetName = 'Query')]
        [byte]$Mask_Length,

        [Parameter(ParameterSetName = 'Query')]
        [string]$VRF,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Device_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Virtual_Machine,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Virtual_Machine_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Interface_Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Role,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving IPAM Address"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($IP_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', $IP_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}
