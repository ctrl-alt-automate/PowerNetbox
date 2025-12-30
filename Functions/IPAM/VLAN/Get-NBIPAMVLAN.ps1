<#
.SYNOPSIS
    Retrieves VLAN objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves VLAN objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIIPAM VLAN

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMVLAN {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [ValidateRange(1, 4096)]
        [uint16]$VID,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$TenantGroup,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$TenantGroup_Id,

        [Parameter(ParameterSetName = 'Query')]
        [object]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Region,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving IPAM VLAN"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($VLAN_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans', $VLAN_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}
