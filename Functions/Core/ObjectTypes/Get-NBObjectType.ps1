<#
.SYNOPSIS
    Retrieves object types from Netbox.

.DESCRIPTION
    Retrieves object types (content types) from Netbox Core module.
    Supports Netbox 4.0+ with automatic endpoint detection:
    - Netbox 4.4+: /api/core/object-types/
    - Netbox 4.0-4.3: /api/extras/object-types/

.PARAMETER Id
    Database ID of the object type.

.PARAMETER App_Label
    Filter by app label (e.g., "dcim", "ipam").

.PARAMETER Model
    Filter by model name (e.g., "device", "ipaddress").

.PARAMETER Query
    Search query.

.PARAMETER Limit
    Number of results to return.

.PARAMETER Offset
    Result offset for pagination.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Get-NBObjectType

.EXAMPLE
    Get-NBObjectType -App_Label "dcim"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBObjectType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$App_Label,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Model,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Object Type"

        # Version-aware endpoint selection
        # - Netbox 4.4+: /api/core/object-types/
        # - Netbox 4.0-4.3: /api/extras/object-types/
        $ObjectTypesModule = 'core'
        $version = $script:NetboxConfig.ParsedVersion
        if ($version -and $version -lt [version]'4.4') {
            $ObjectTypesModule = 'extras'
            Write-Verbose "Using /api/extras/object-types/ endpoint (Netbox $version)"
        } else {
            Write-Verbose "Using /api/core/object-types/ endpoint (Netbox $version)"
        }

        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@($ObjectTypesModule, 'object-types', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@($ObjectTypesModule, 'object-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
