
function Get-NBContactAssignment {
<#
    .SYNOPSIS
        Get a contact Assignment from Netbox

    .DESCRIPTION
        Retrieves contact assignments from Netbox. Contact assignments link contacts
        to objects (devices, sites, circuits, etc.) with a specific role.

    .PARAMETER Name
        The specific name of the contact assignment.

    .PARAMETER Id
        The database ID of the contact assignment.

    .PARAMETER Content_Type_Id
        Filter by content type database ID.

    .PARAMETER Content_Type
        Filter by content type name (e.g., 'dcim.device', 'dcim.site').

    .PARAMETER Object_Id
        Filter by the assigned object's database ID.

    .PARAMETER Contact_Id
        Filter by contact database ID.

    .PARAMETER Role_Id
        Filter by contact role database ID.

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NBContactAssignment

#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Content_Type_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Content_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Object_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Contact_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Contact Assignment"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($ContactAssignment_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments', $ContactAssignment_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}
