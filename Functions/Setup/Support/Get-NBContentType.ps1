function Get-NBContentType {
<#
    .SYNOPSIS
        Get a content type definition from Netbox

    .DESCRIPTION
        A detailed description of the Get-NBContentType function.

    .PARAMETER Model
        A description of the Model parameter.

    .PARAMETER Id
        The database ID of the contact role

    .PARAMETER App_Label
        A description of the App_Label parameter.

    .PARAMETER Query
        A standard search query that will match one or more contact roles.

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NBContentType

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param
    (
        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Model,

        [Parameter(ParameterSetName = 'ByID')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$App_Label,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($ContentType_ID in $Id) {
                # Netbox 4.x moved content-types from /extras/ to /core/object-types/
                $Segments = [System.Collections.ArrayList]::new(@('core', 'object-types', $ContentType_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw
            }

            break
        }

        default {
            # Netbox 4.x moved content-types from /extras/ to /core/object-types/
            $Segments = [System.Collections.ArrayList]::new(@('core', 'object-types'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw

            break
        }
    }
}