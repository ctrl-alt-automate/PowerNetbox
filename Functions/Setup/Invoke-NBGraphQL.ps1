<#
.SYNOPSIS
    Executes a GraphQL query against the Netbox API.

.DESCRIPTION
    Invokes GraphQL queries against Netbox's /graphql/ endpoint. GraphQL provides efficient
    querying with precise field selection, reducing over-fetching compared to REST.

    This function supports:
    - Raw GraphQL queries with field selection
    - Parameterized queries with variables
    - Multiple operations with operation name selection
    - Result path extraction for convenient data access

    Note: Netbox GraphQL is read-only (no mutations available).

.PARAMETER Query
    The GraphQL query string. Supports:
    - Simple queries: { device_list { id name } }
    - Named queries: query GetDevices { device_list { id } }
    - Parameterized queries: query GetDevices($limit: Int!) { device_list(pagination: {limit: $limit}) { id } }

.PARAMETER Variables
    Hashtable of variables to substitute in parameterized queries.
    Variables are serialized to JSON and sent with the request.

.PARAMETER OperationName
    The name of the operation to execute when the query contains multiple named operations.

.PARAMETER ResultPath
    Dot-notation path to extract specific data from the response.
    Example: -ResultPath 'device_list' returns the array directly instead of { data: { device_list: [...] } }

.PARAMETER Raw
    Return the complete GraphQL response including potential errors array.
    Without -Raw, only the data property is returned (or throws on errors).

.PARAMETER Timeout
    Request timeout in seconds. Defaults to the global timeout set via Set-NBTimeout or Connect-NBAPI.
    Useful for complex queries that may take longer to execute.

.OUTPUTS
    [PSCustomObject] The query results or extracted data based on ResultPath.

.EXAMPLE
    Invoke-NBGraphQL -Query '{ site_list { id name } }'

    Returns all sites with their id and name fields.

.EXAMPLE
    Invoke-NBGraphQL -Query '{ device_list { id name status } }' -ResultPath 'device_list'

    Returns the device array directly, extracting it from the response.

.EXAMPLE
    $query = @'
    query GetActiveDevices($limit: Int!, $status: DeviceStatusEnum) {
        device_list(
            filters: { status: $status }
            pagination: { limit: $limit }
        ) {
            id
            name
            site { name }
            primary_ip4 { address }
        }
    }
    '@

    Invoke-NBGraphQL -Query $query -Variables @{
        limit = 50
        status = "STATUS_ACTIVE"
    } -ResultPath 'device_list'

    Fetches active devices with nested site and IP information using variables.

.EXAMPLE
    # Complex nested query - replaces multiple REST calls
    $query = @'
    {
        device_list(filters: { role: { name: { exact: "switch" } } }) {
            name
            serial
            site {
                name
                region { name }
            }
            primary_ip4 { address }
            interfaces {
                name
                ip_addresses { address }
            }
        }
    }
    '@

    $switches = Invoke-NBGraphQL -Query $query -ResultPath 'device_list'

    Gets all switches with their site, region, IPs, and interfaces in a single query.

.EXAMPLE
    $result = Invoke-NBGraphQL -Query '{ invalid_field }' -Raw
    if ($result.errors) {
        Write-Warning "Query errors: $($result.errors.message -join ', ')"
    }

    Uses -Raw to handle errors manually instead of throwing.

.EXAMPLE
    # Pagination example
    Invoke-NBGraphQL -Query '{ device_list(pagination: { limit: 10, offset: 20 }) { id name } }'

    Fetches devices 21-30 using GraphQL pagination.

.EXAMPLE
    # Pipeline support - execute queries from file
    Get-Content ./queries.graphql | Invoke-NBGraphQL

    Executes GraphQL queries read from a file.

.NOTES
    Requires Netbox 3.0+ for GraphQL support.
    Advanced filtering syntax (OR/NOT operators, custom fields) requires Netbox 4.3+.

    Pagination:
    - Default limit is 100 items per query (Netbox server default)
    - Use pagination: { limit: N, offset: M } to control results
    - For large datasets, implement client-side pagination

    Filter Syntax for Netbox 4.3/4.4:
    - ID filters: { id: 1 }
    - Enum filters: { status: STATUS_ACTIVE }
    - Nested filters: { site: { name: { exact: "Amsterdam" } } }
    - OR filters: { status: STATUS_ACTIVE, OR: { status: STATUS_PLANNED } }

    Note: Netbox 4.5+ requires different filter syntax. See wiki for version-specific examples.

.LINK
    https://netbox.readthedocs.io/en/stable/integrations/graphql/

.LINK
    https://github.com/ctrl-alt-automate/PowerNetbox/wiki/GraphQL-Examples
#>
function Invoke-NBGraphQL {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,

        [Parameter()]
        [hashtable]$Variables,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OperationName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ResultPath,

        [Parameter()]
        [switch]$Raw,

        [Parameter()]
        [uint16]$Timeout
    )

    begin {
        # Ensure we're connected
        CheckNetboxIsConnected

        # Version check - warn if below 4.3 (limited filter support)
        if ($script:NetboxConfig.ParsedVersion -and $script:NetboxConfig.ParsedVersion -lt [version]'4.3.0') {
            Write-Warning "Netbox version $($script:NetboxConfig.ParsedVersion) detected. Advanced GraphQL filtering (OR/NOT, custom fields) requires Netbox 4.3+."
        }
    }

    process {
        # Build the GraphQL request body
        $body = @{
            query = $Query
        }

        if ($Variables) {
            $body.variables = $Variables
            Write-Verbose "GraphQL variables: $($Variables | ConvertTo-Json -Compress)"
        }

        if ($OperationName) {
            $body.operationName = $OperationName
            Write-Verbose "GraphQL operation: $OperationName"
        }

        # Build URI for GraphQL endpoint
        # Note: GraphQL endpoint is /graphql/, NOT /api/graphql/
        # So we build the URI directly instead of using BuildNewURI
        $uri = [System.UriBuilder]::new(
            $script:NetboxConfig.HostScheme,
            $script:NetboxConfig.Hostname,
            $script:NetboxConfig.HostPort,
            'graphql/'
        )

        Write-Verbose "Invoking GraphQL query against $($uri.Uri.AbsoluteUri)"
        Write-Verbose "Query: $($Query -replace '\s+', ' ' | ForEach-Object { if ($_.Length -gt 200) { $_.Substring(0, 200) + '...' } else { $_ } })"

        # Execute the request - always get raw response to check for GraphQL errors
        $invokeParams = @{
            URI    = $uri
            Method = 'POST'
            Body   = $body
            Raw    = $true
        }
        if ($Timeout) {
            $invokeParams.Timeout = $Timeout
        }
        $response = InvokeNetboxRequest @invokeParams

        # Handle GraphQL-specific error responses
        # GraphQL returns errors in the response body, not via HTTP status codes
        if ($response.errors) {
            $errorMessages = ($response.errors | ForEach-Object { $_.message }) -join "; "

            if (-not $Raw) {
                # Provide helpful hints for common issues
                # Note: Check enum pattern FIRST since it also contains 'FilterLookup'
                if ($errorMessages -match "Expected value of type '\w+EnumBaseFilterLookup'") {
                    Write-Warning "Hint: Netbox 4.5+ requires new enum filter syntax. Use { status: { exact: STATUS_X } } instead of { status: STATUS_X }"
                }
                elseif ($errorMessages -match "Expected value of type 'IDFilterLookup'") {
                    Write-Warning "Hint: Netbox 4.5+ requires new ID filter syntax. Use { id: { exact: N } } instead of { id: N }"
                }
                elseif ($errorMessages -match 'Cannot query field') {
                    Write-Warning "Hint: Check field names against the GraphQL schema. Use introspection: { __schema { types { name } } }"
                }

                # Throw structured error
                $ex = [System.InvalidOperationException]::new("GraphQL query failed: $errorMessages")
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    $ex,
                    'GraphQLQueryFailed',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Query
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        # Return raw response if requested
        if ($Raw) {
            return $response
        }

        # Extract data from response
        $result = $response.data

        # Handle null data (shouldn't happen without errors, but be defensive)
        if ($null -eq $result) {
            return $null
        }

        # Apply ResultPath extraction if specified
        if ($ResultPath) {
            foreach ($segment in $ResultPath.Split('.')) {
                if ($null -eq $result) {
                    Write-Verbose "ResultPath '$ResultPath' returned null at segment '$segment'"
                    break
                }
                $result = $result.$segment
            }
        }

        return $result
    }
}
