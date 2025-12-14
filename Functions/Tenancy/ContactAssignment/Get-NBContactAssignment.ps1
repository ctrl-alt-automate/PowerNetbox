
function Get-NBContactAssignment {
<#
    .SYNOPSIS
        Get a contact Assignment from Netbox

    .DESCRIPTION
        A detailed description of the Get-NBContactAssignment function.

    .PARAMETER Name
        The specific name of the contact Assignment. Must match exactly as is defined in Netbox

    .PARAMETER Id
        The database ID of the contact Assignment

    .PARAMETER Content_Type_Id
        A description of the Content_Type_Id parameter.

    .PARAMETER Content_Type
        A description of the Content_Type parameter.

    .PARAMETER Object_Id
        A description of the Object_Id parameter.

    .PARAMETER Contact_Id
        A description of the Contact_Id parameter.

    .PARAMETER Role_Id
        A description of the Role_Id parameter.

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NBContactAssignment

    .NOTES
        Additional information about the function.
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
