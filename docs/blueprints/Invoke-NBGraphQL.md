# Blueprint: Invoke-NBGraphQL

## Overview

PowerShell wrapper for NetBox's GraphQL API endpoint, enabling efficient complex queries with precise field selection and reduced over-fetching.

## Research Summary

Based on testing against NetBox 4.4.7:

| Property | Value |
|----------|-------|
| Endpoint | `/graphql/` (POST only) |
| Authentication | Token-based (same as REST) |
| Schema types | 378 types, 236 root queries |
| Mutations | **None** - GraphQL is read-only |
| Pagination | Offset-based (`limit`, `offset`) |

## Function Signature

```powershell
function Invoke-NBGraphQL {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        # The GraphQL query string
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,

        # Variables to pass to the query (hashtable)
        [Parameter()]
        [hashtable]$Variables,

        # Operation name (for queries with multiple operations)
        [Parameter()]
        [string]$OperationName,

        # Return raw response including errors array
        [Parameter()]
        [switch]$Raw,

        # Path to extract from response (e.g., "device_list")
        [Parameter()]
        [string]$ResultPath
    )
}
```

## Parameters

### -Query (Mandatory)
The GraphQL query string. Supports:
- Simple queries: `{ device_list { id name } }`
- Named queries: `query GetDevices { ... }`
- Parameterized queries: `query GetDevices($limit: Int!) { ... }`

### -Variables
Hashtable of variables to substitute in the query. Automatically serialized to JSON.

```powershell
-Variables @{ limit = 10; status = "STATUS_ACTIVE" }
```

### -OperationName
Required when query contains multiple named operations.

### -Raw
Returns the complete GraphQL response including:
- `data` - The query results
- `errors` - Array of any errors

Without `-Raw`, only the `data` property is returned (or throws on errors).

### -ResultPath
Dot-notation path to extract specific data from the response.

```powershell
# Instead of $result.data.device_list
Invoke-NBGraphQL -Query "{ device_list { id } }" -ResultPath "device_list"
```

## Implementation Details

### 1. Request Construction

```powershell
$body = @{
    query = $Query
}

if ($Variables) {
    $body.variables = $Variables
}

if ($OperationName) {
    $body.operationName = $OperationName
}

$jsonBody = $body | ConvertTo-Json -Depth 10 -Compress
```

### 2. API Call

```powershell
$uri = BuildNewURI -Segments @('graphql')
$response = InvokeNetboxRequest -URI $uri -Method POST -Body $jsonBody -Raw
```

**Note**: May need to bypass `BuildURIComponents` since GraphQL doesn't use query parameters.

### 3. Error Handling

GraphQL returns errors differently than REST:

```json
{
  "data": null,
  "errors": [
    {
      "message": "Field 'invalid' not found",
      "locations": [{ "line": 1, "column": 10 }]
    }
  ]
}
```

**Strategy:**
- If `errors` present and `-Raw` not specified → throw terminating error
- If `errors` present and `-Raw` specified → return full response
- If `data` is null without errors → return `$null`

```powershell
if ($response.errors -and -not $Raw) {
    $errorMessages = ($response.errors | ForEach-Object { $_.message }) -join "; "
    throw "GraphQL query failed: $errorMessages"
}

if ($Raw) {
    return $response
}

$result = $response.data

if ($ResultPath) {
    foreach ($segment in $ResultPath.Split('.')) {
        $result = $result.$segment
    }
}

return $result
```

### 4. Authentication Edge Case

Without authentication, NetBox returns HTML login page instead of JSON error.
Must detect and handle gracefully:

```powershell
# In InvokeNetboxRequest or here
if ($response -is [string] -and $response -match '<!DOCTYPE html>') {
    throw "Authentication required. Use Connect-NBAPI first."
}
```

## Usage Examples

### Basic Query

```powershell
# Simple query
Invoke-NBGraphQL -Query '{ device_list { id name status } }'

# With result path extraction
Invoke-NBGraphQL -Query '{ device_list { id name } }' -ResultPath 'device_list'
```

### With Variables

```powershell
$query = @'
query GetDevices($limit: Int!, $status: DeviceStatusEnum) {
  device_list(
    filters: { status: $status }
    pagination: { limit: $limit }
  ) {
    id
    name
    status
  }
}
'@

Invoke-NBGraphQL -Query $query -Variables @{
    limit = 10
    status = "STATUS_ACTIVE"
} -ResultPath 'device_list'
```

### Complex Nested Query

```powershell
# Get all switches in a region with their IP addresses - single query!
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
      enabled
      ip_addresses { address }
    }
  }
}
'@

$switches = Invoke-NBGraphQL -Query $query -ResultPath 'device_list'
```

### Error Handling

```powershell
# Get raw response including errors
$response = Invoke-NBGraphQL -Query '{ invalid_query }' -Raw
if ($response.errors) {
    Write-Warning "Query had errors: $($response.errors.message -join ', ')"
}

# Or let it throw
try {
    Invoke-NBGraphQL -Query '{ invalid_query }'
} catch {
    Write-Error "GraphQL failed: $_"
}
```

### Introspection

```powershell
# Get available types
$schema = Invoke-NBGraphQL -Query '{
  __schema {
    types { name kind }
  }
}' -ResultPath '__schema.types'

# Get fields for a specific type
$deviceFields = Invoke-NBGraphQL -Query '{
  __type(name: "DeviceType") {
    fields { name type { name } }
  }
}' -ResultPath '__type.fields'
```

## Helper Functions (Optional Future Scope)

### Get-NBGraphQLSchema

```powershell
function Get-NBGraphQLSchema {
    # Returns introspection data for exploring available queries
}
```

### ConvertTo-NBGraphQLFilter

```powershell
function ConvertTo-NBGraphQLFilter {
    # Converts PowerShell hashtable to GraphQL filter syntax
    # Handles enum conversion (active → STATUS_ACTIVE)
}
```

## Testing Strategy

### Unit Tests

1. Query string construction
2. Variable serialization
3. Error response parsing
4. ResultPath extraction
5. Parameter validation

### Integration Tests

1. Simple query execution
2. Query with variables
3. Nested data retrieval
4. Error handling (invalid query)
5. Authentication requirement
6. Pagination

## File Location

```
Functions/
└── Setup/
    └── Invoke-NBGraphQL.ps1
```

Or alternatively in a new GraphQL folder:
```
Functions/
└── GraphQL/
    └── Invoke-NBGraphQL.ps1
```

## Dependencies

- `BuildNewURI` - URI construction
- `InvokeNetboxRequest` - Or direct `Invoke-RestMethod` for special handling
- `Get-NBCredential` - Authentication token
- `CheckNetboxIsConnected` - Connection validation

## Open Questions

1. **Location**: Should this be in `Setup/` (like Connect-NBAPI) or new `GraphQL/` folder?
2. **Caching**: Should we cache schema introspection results?
3. **Query validation**: Should we validate queries against schema before sending?
4. **Enum helpers**: Should we auto-convert `active` → `STATUS_ACTIVE`?

## Version Requirements

- NetBox: 3.0+ (GraphQL introduced in 3.0)
- PowerShell: 5.1+ (same as module)

## Related

- [NetBox GraphQL Docs](https://netbox.readthedocs.io/en/stable/integrations/graphql/)
- [GraphQL Specification](https://graphql.org/learn/)
