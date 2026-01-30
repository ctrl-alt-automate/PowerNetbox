function Get-NBContentType {
<#
    .SYNOPSIS
        Get a content type (object type) definition from Netbox

    .DESCRIPTION
        Retrieves content type / object type definitions from Netbox.
        Supports Netbox 4.0+ with automatic endpoint detection:
        - Netbox 4.4+: /api/core/object-types/
        - Netbox 4.0-4.3: /api/extras/object-types/

    .PARAMETER Model
        Filter by model name (e.g., 'device', 'site')

    .PARAMETER Id
        The database ID of the content type

    .PARAMETER App_Label
        Filter by app label (e.g., 'dcim', 'ipam')

    .PARAMETER Query
        A standard search query

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Start the search at this index

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Get-NBContentType -App_Label 'dcim'
        Get all DCIM content types

    .EXAMPLE
        PS C:\> Get-NBContentType -Model 'device'
        Get the device content type

    .NOTES
        Backward compatible with Netbox 4.0+
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

    # Determine the correct endpoint based on Netbox version
    # - Netbox 4.4+: /api/core/object-types/ (primary)
    # - Netbox 4.0-4.3: /api/extras/object-types/ (legacy, still works in 4.4 for backward compat)
    # We use 'extras' as the default for maximum compatibility across all 4.x versions
    $ObjectTypesEndpoint = @('extras', 'object-types')

    # Use cached ParsedVersion from Connect-NBAPI (set by ConvertTo-NetboxVersion)
    $version = $script:NetboxConfig.ParsedVersion
    if ($version -and $version -ge [version]'4.4') {
        $ObjectTypesEndpoint = @('core', 'object-types')
        Write-Verbose "Using /api/core/object-types/ endpoint (Netbox $version)"
    } else {
        Write-Verbose "Using /api/extras/object-types/ endpoint (Netbox $version)"
    }

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($ContentType_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@($ObjectTypesEndpoint[0], $ObjectTypesEndpoint[1], $ContentType_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'All', 'PageSize'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@($ObjectTypesEndpoint[0], $ObjectTypesEndpoint[1]))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'All', 'PageSize'

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
}