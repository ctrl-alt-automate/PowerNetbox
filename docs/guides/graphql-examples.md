# GraphQL Examples

PowerNetbox provides `Invoke-NBGraphQL` for executing GraphQL queries against NetBox. GraphQL offers efficient querying with precise field selection, reducing over-fetching compared to REST.

## Overview

| Property | Value |
|----------|-------|
| Endpoint | `/graphql/` |
| Method | POST only |
| Mutations | Not available (read-only) |
| Min. Version | NetBox 3.0+ |
| Advanced Filters | NetBox 4.3+ |

## Basic Usage

### Simple Query

```powershell
# Get all sites with id and name
Invoke-NBGraphQL -Query '{ site_list { id name } }'

# Extract the results directly with -ResultPath
$sites = Invoke-NBGraphQL -Query '{ site_list { id name status } }' -ResultPath 'site_list'
```

### Query with Field Selection

```powershell
# Only request the fields you need
$devices = Invoke-NBGraphQL -Query '{
    device_list {
        id
        name
        serial
        status
    }
}' -ResultPath 'device_list'
```

## Filtering

### Status Filter (Netbox 4.3/4.4)

```powershell
# Filter by status enum
$activeDevices = Invoke-NBGraphQL -Query '{
    device_list(filters: { status: STATUS_ACTIVE }) {
        id
        name
    }
}' -ResultPath 'device_list'
```

### Nested Filters

```powershell
# Filter by related object properties
$result = Invoke-NBGraphQL -Query '{
    device_list(filters: { site: { name: { exact: "Amsterdam Datacenter" } } }) {
        id
        name
        site { name }
    }
}' -ResultPath 'device_list'
```

### OR Filters

```powershell
# Combine filters with OR
$result = Invoke-NBGraphQL -Query '{
    device_list(filters: {
        status: STATUS_ACTIVE,
        OR: { status: STATUS_PLANNED }
    }) {
        id
        name
        status
    }
}' -ResultPath 'device_list'
```

## Variables

Use variables for parameterized queries:

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
        site { name }
    }
}
'@

$devices = Invoke-NBGraphQL -Query $query -Variables @{
    limit  = 50
    status = 'STATUS_ACTIVE'
} -ResultPath 'device_list'
```

## Pagination

```powershell
# Limit and offset
$page1 = Invoke-NBGraphQL -Query '{
    device_list(pagination: { limit: 10, offset: 0 }) {
        id
        name
    }
}' -ResultPath 'device_list'

$page2 = Invoke-NBGraphQL -Query '{
    device_list(pagination: { limit: 10, offset: 10 }) {
        id
        name
    }
}' -ResultPath 'device_list'
```

## Complex Nested Queries

One of GraphQL's biggest advantages is fetching related data in a single query:

```powershell
# Get switches with site, region, IPs, and interfaces - ONE query!
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

# Process the results
$switches | ForEach-Object {
    Write-Host "$($_.name) at $($_.site.name) - $($_.primary_ip4.address)"
}
```

## Error Handling

### Default Error Handling

```powershell
# Throws exception on GraphQL errors
try {
    Invoke-NBGraphQL -Query '{ invalid_field }'
}
catch {
    Write-Error "Query failed: $_"
}
```

### Raw Response for Manual Handling

```powershell
# Get raw response including errors
$response = Invoke-NBGraphQL -Query '{ invalid_field }' -Raw

if ($response.errors) {
    Write-Warning "Query had errors:"
    $response.errors | ForEach-Object { Write-Warning "  - $($_.message)" }
}
else {
    # Process $response.data
}
```

## Schema Introspection

Explore the GraphQL schema:

```powershell
# Get all available types
$types = Invoke-NBGraphQL -Query '{
    __schema {
        types { name kind }
    }
}' -ResultPath '__schema.types'

$types | Where-Object { $_.kind -eq 'OBJECT' } | Select-Object -First 20

# Get fields for a specific type
$deviceFields = Invoke-NBGraphQL -Query '{
    __type(name: "DeviceType") {
        fields {
            name
            type { name kind }
        }
    }
}' -ResultPath '__type.fields'

$deviceFields | Format-Table name, @{N='Type';E={$_.type.name}}
```

## Pipeline Support

```powershell
# Execute queries from file
Get-Content ./queries.graphql | Invoke-NBGraphQL

# Execute multiple queries
@(
    '{ site_list { id name } }',
    '{ device_list { id name } }',
    '{ prefix_list { id prefix } }'
) | Invoke-NBGraphQL -ResultPath 'site_list' # Note: ResultPath applies to all
```

## Real-World Use Cases

### Inventory Report

```powershell
# Single query for comprehensive device report
$query = @'
{
    device_list {
        name
        serial
        asset_tag
        status
        device_type { model manufacturer { name } }
        site { name region { name } }
        rack { name }
        position
        primary_ip4 { address }
        primary_ip6 { address }
    }
}
'@

$inventory = Invoke-NBGraphQL -Query $query -ResultPath 'device_list'

$inventory | Select-Object name, serial,
    @{N='Manufacturer';E={$_.device_type.manufacturer.name}},
    @{N='Model';E={$_.device_type.model}},
    @{N='Site';E={$_.site.name}},
    @{N='IPv4';E={$_.primary_ip4.address}} |
    Export-Csv -Path 'inventory.csv' -NoTypeInformation
```

### Network Topology

```powershell
# Get device connections
$query = @'
{
    device_list(filters: { role: { name: { exact: "switch" } } }) {
        name
        interfaces {
            name
            cable {
                id
                a_terminations { ... on InterfaceType { device { name } name } }
                b_terminations { ... on InterfaceType { device { name } name } }
            }
        }
    }
}
'@

$topology = Invoke-NBGraphQL -Query $query -ResultPath 'device_list'
```

## Version Compatibility Notes

### NetBox 4.3/4.4 Filter Syntax

```graphql
# ID filters - use scalar value
device_list(filters: { id: 1 })

# Enum filters - use direct value
device_list(filters: { status: STATUS_ACTIVE })
```

### NetBox 4.5+ Filter Syntax (Breaking Change)

```graphql
# ID filters - must use { exact: N }
device_list(filters: { id: { exact: 1 } })

# Enum filters - must use { exact: VALUE }
device_list(filters: { status: { exact: STATUS_ACTIVE } })

# New in_list capability
device_list(filters: { id: { in_list: [1, 2, 3] } })
```

PowerNetbox will show helpful warnings when you encounter 4.5 syntax errors on older versions.

## Parameters Reference

| Parameter | Type | Description |
|-----------|------|-------------|
| `-Query` | String | The GraphQL query (required) |
| `-Variables` | Hashtable | Variables for parameterized queries |
| `-OperationName` | String | Operation name (for multi-operation queries) |
| `-ResultPath` | String | Dot-notation path to extract (e.g., 'device_list') |
| `-Raw` | Switch | Return complete response including errors |

## Related Resources

- [NetBox GraphQL Documentation](https://netbox.readthedocs.io/en/stable/integrations/graphql/)
- [GraphQL Specification](https://graphql.org/learn/)
- [Issue #142 - Invoke-NBGraphQL](https://github.com/ctrl-alt-automate/PowerNetbox/issues/142)
