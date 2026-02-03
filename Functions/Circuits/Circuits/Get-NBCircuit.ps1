
function Get-NBCircuit {
    <#
    .SYNOPSIS
        Gets one or more circuits

    .DESCRIPTION
        Retrieves circuit objects from Netbox. Circuits represent physical or virtual
        connections between sites, typically provided by external carriers or ISPs.

    .PARAMETER Id
        Database ID of circuit. This will query for exactly the IDs provided

    .PARAMETER CID
        Circuit ID. Also accepts -Name alias for consistency with other Get- functions.

    .PARAMETER InstallDate
        Date of installation

    .PARAMETER CommitRate
        Committed rate in Kbps

    .PARAMETER Query
        A raw search query... As if you were searching the web site

    .PARAMETER Provider
        The name or database ID of the provider.
        - String: Searches by provider name (e.g., 'Comcast')
        - Integer: Searches by database ID (e.g., 1)

    .PARAMETER ProviderId
        Alias for Provider. Database ID of the provider (uint64).

    .PARAMETER Type
        The name or database ID of the circuit type.
        - String: Searches by type name (e.g., 'Internet')
        - Integer: Searches by database ID (e.g., 1)

    .PARAMETER TypeId
        Alias for Type. Database ID of the circuit type (uint64).

    .PARAMETER Site
        Location/site of circuit. Provide either [string] or [uint64]. String will search site names, integer will search database IDs

    .PARAMETER Tenant
        Tenant assigned to circuit. Provide either [string] or [uint64]. String will search tenant names, integer will search database IDs

    .PARAMETER Limit
        Maximum number of results to return (1-1000). Default is determined by Netbox server.

    .PARAMETER Offset
        Number of results to skip before returning. Use with Limit for pagination.

    .PARAMETER Raw
        Return the raw API response instead of extracting the results array.

    .PARAMETER ID__IN
        Multiple unique DB IDs to retrieve

    .EXAMPLE
        PS C:\> Get-NBCircuit

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


        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ById')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('Name')]
        [string]$CID,

        [Parameter(ParameterSetName = 'Query')]
        [datetime]$InstallDate,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$CommitRate,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('ProviderId', 'Provider_Id')]
        [object]$Provider,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('TypeId', 'Type_Id')]
        [object]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving Circuit"
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $ID) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits', $i))

                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'All', 'PageSize'

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
