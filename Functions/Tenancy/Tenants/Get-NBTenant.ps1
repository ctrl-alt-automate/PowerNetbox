
function Get-NBTenant {
<#
    .SYNOPSIS
        Get a tenant from Netbox

    .DESCRIPTION
        Retrieves tenant objects from Netbox. Tenants represent organizations or
        customers that own or use resources tracked in Netbox.

    .PARAMETER Name
        The specific name of the tenant. Must match exactly as is defined in Netbox

    .PARAMETER Id
        The database ID of the tenant

    .PARAMETER Query
        A standard search query that will match one or more tenants.

    .PARAMETER Slug
        The specific slug of the tenant. Must match exactly as is defined in Netbox

    .PARAMETER Group
        The specific group as defined in Netbox.

    .PARAMETER GroupID
        The database ID of the group in Netbox

    .PARAMETER Custom_Fields
        Hashtable in the format @{"field_name" = "value"} to search

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NBTenant

#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$GroupID,

        [Parameter(ParameterSetName = 'Query')]
        [hashtable]$Custom_Fields,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Tenant"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Tenant_Id in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants', $Tenant_Id))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'tenants'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}
