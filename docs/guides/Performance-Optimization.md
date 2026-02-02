# Performance Optimization

PowerNetbox implements [NetBox REST API best practices](https://github.com/netboxlabs/netbox-best-practices) to optimize API performance. These features can dramatically reduce response times and payload sizes.

## Overview

| Feature | Parameter | Effect | Best For |
|---------|-----------|--------|----------|
| Brief Mode | `-Brief` | ~90% smaller payload | Dropdowns, lists |
| Field Selection | `-Fields` | Custom fields only | Reports, specific needs |
| Exclude Config Context | Default behavior | 10-100x faster | Most device/VM queries |
| Include Config Context | `-IncludeConfigContext` | Include config_context | When you need rendered config |

## Brief Mode

The `-Brief` switch returns a minimal representation of objects containing only essential fields: `id`, `url`, `display`, and `name`.

```powershell
# Full response (all fields)
Get-NBDCIMDevice -Name 'server01'

# Brief response (~90% smaller)
Get-NBDCIMDevice -Name 'server01' -Brief
```

### When to Use Brief Mode

- **Dropdowns and select lists** - You only need id and name
- **Reference lookups** - Finding IDs for related objects
- **Large result sets** - When processing many objects
- **Low-bandwidth connections** - Minimize data transfer

### Example: Populate a Dropdown

```powershell
# Get all sites for a dropdown (minimal data)
$sites = Get-NBDCIMSite -Brief

# Returns objects like:
# @{
#     id = 1
#     url = 'https://netbox.example.com/api/dcim/sites/1/'
#     display = 'Main DC'
#     name = 'Main DC'
# }
```

## Field Selection

The `-Fields` parameter allows you to specify exactly which fields to include in the response. This is more flexible than Brief mode when you need specific fields.

```powershell
# Get only specific fields
Get-NBDCIMDevice -Fields 'id','name','status','serial'

# Include nested fields (use dot notation)
Get-NBDCIMDevice -Fields 'id','name','site.name','device_type.model'
```

### When to Use Field Selection

- **Reports** - Extract specific data for reporting
- **Data export** - Get only the fields you need
- **Custom dashboards** - Reduce API overhead
- **Performance-critical scripts** - Minimize data transfer

### Example: Export Device Report

```powershell
# Get device data for a report
$devices = Get-NBDCIMDevice -Status 'active' -Fields 'id','name','serial','site.name','rack.name'

# Export to CSV
$devices | Select-Object id, name, serial,
    @{N='Site';E={$_.site.name}},
    @{N='Rack';E={$_.rack.name}} |
    Export-Csv -Path 'devices.csv' -NoTypeInformation
```

## Config Context Exclusion

By default, PowerNetbox excludes `config_context` from device and VM responses. This can improve performance by **10-100x** because config_context requires server-side rendering of hierarchical configuration data.

### Default Behavior (Fast)

```powershell
# config_context is automatically excluded
Get-NBDCIMDevice

# Equivalent to:
# GET /api/dcim/devices/?exclude=config_context
```

### Include Config Context When Needed

```powershell
# Explicitly include config_context
Get-NBDCIMDevice -IncludeConfigContext

# Or for a specific device
Get-NBDCIMDevice -Id 1 -IncludeConfigContext
```

### When to Include Config Context

- **Configuration management** - Generating device configs
- **Ansible/Terraform** - Using Netbox as source of truth
- **Automation scripts** - When you need rendered configuration

### Performance Impact

| Scenario | Without config_context | With config_context |
|----------|------------------------|---------------------|
| 100 devices | ~200ms | ~2-20 seconds |
| 1000 devices | ~2 seconds | ~20-200 seconds |
| Complex hierarchy | Minimal impact | Significant slowdown |

## Query Parameter Warning

The `-Query` parameter performs a broad text search across multiple fields. On large datasets, this can be slow.

```powershell
# This triggers a warning
Get-NBDCIMDevice -Query 'server'
# WARNING: The -Query parameter can be slow on large datasets.
# Consider using specific filters like -Name for better performance.

# Better: Use specific filters
Get-NBDCIMDevice -Name 'server*'
Get-NBDCIMDevice -Name__ic 'server'  # Case-insensitive contains
```

### Filter Alternatives

| Instead of | Use |
|------------|-----|
| `-Query 'server'` | `-Name 'server*'` or `-Name__ic 'server'` |
| `-Query '10.0.0'` | `-Address__startswith '10.0.0'` |
| `-Query 'DC1'` | `-Site_Id 1` or `-Site 'DC1'` |

## Combining Optimizations

For maximum performance, combine multiple optimization techniques:

```powershell
# Most efficient: specific filters + brief mode
Get-NBDCIMDevice -Site_Id 1 -Status 'active' -Brief

# For reports: specific filters + field selection
Get-NBDCIMDevice -Site_Id 1 -Fields 'id','name','status','primary_ip4.address'

# Pagination for large datasets
Get-NBDCIMDevice -Status 'active' -Brief -Limit 100 -Offset 0
```

## Best Practices Summary

1. **Always use specific filters** instead of `-Query`
2. **Use `-Brief`** for dropdowns and reference lists
3. **Use `-Fields`** for reports and custom data extraction
4. **Let config_context be excluded** by default
5. **Only use `-IncludeConfigContext`** when you need rendered configuration
6. **Use pagination** (`-Limit`, `-Offset`) for large result sets
7. **Use `-All` with `-PageSize`** for automatic pagination

## See Also

- [Getting Started](Getting-Started.md) - Basic setup and connection
- [Bulk Operations](Bulk-Operations.md) - High-performance batch processing
- [Common Workflows](Common-Workflows.md) - Real-world examples
- [NetBox Best Practices](https://github.com/netboxlabs/netbox-best-practices) - Official documentation
