# PowerNetbox Documentation

Welcome to the **PowerNetbox** documentation.

PowerNetbox is a comprehensive PowerShell module for the [Netbox](https://github.com/netbox-community/netbox) REST API with **100% coverage** of all endpoints. Fully compatible with **Netbox 4.3 - 4.5**.

## Quick Start

```powershell
# Install from PSGallery
Install-Module -Name PowerNetbox

# Connect to Netbox
$cred = Get-Credential  # Enter 'api' as username, token as password
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $cred

# Start using it
Get-NBDCIMDevice -Name 'server01'
```

## Guides

| Guide | Description |
|-------|-------------|
| [Getting Started](guides/Getting-Started.md) | Installation and first steps |
| [Common Workflows](guides/Common-Workflows.md) | Real-world use cases and examples |
| [Bulk Operations](guides/Bulk-Operations.md) | High-performance batch create/update/delete |
| [Performance Optimization](guides/Performance-Optimization.md) | Tips for large-scale operations |
| [Branching](guides/Branching.md) | Netbox Branching plugin support |

## Examples by Module

| Module | Guide |
|--------|-------|
| DCIM | [DCIM Examples](guides/DCIM-Examples.md) |
| IPAM | [IPAM Examples](guides/IPAM-Examples.md) |
| GraphQL | [GraphQL Examples](guides/GraphQL-Examples.md) |

## Reference

| Topic | Description |
|-------|-------------|
| [Compatibility](guides/Compatibility.md) | Netbox version support matrix |
| [Function Naming](guides/Function-Naming.md) | Naming conventions and patterns |
| [Troubleshooting](guides/Troubleshooting.md) | Solutions to common issues |

## Contributing

- [Development Practices](guides/Development-Practices.md) - How to contribute

## Features

| Feature | Description |
|---------|-------------|
| **524 Functions** | Complete CRUD operations for all Netbox resources |
| **100% API Coverage** | All Netbox 4.x modules supported |
| **Cross-Platform** | Windows, Linux, and macOS |
| **Pipeline Support** | Full PowerShell pipeline integration |
| **Bulk Operations** | High-performance batch operations with automatic error recovery |
| **Tab Completion** | Argument completers for common parameters |
| **Verbose Logging** | Write-Verbose in all functions for debugging |
| **Well Tested** | 1436 unit tests, 98 integration tests |

## Supported Modules

| Module | Functions | Description |
|--------|-----------|-------------|
| DCIM | 180 | Sites, devices, racks, cables, interfaces |
| IPAM | 72 | IP addresses, prefixes, VLANs, VRFs |
| Virtualization | 20 | VMs, clusters, VM interfaces |
| Circuits | 44 | Circuits, providers, terminations |
| Tenancy | 20 | Tenants, contacts |
| VPN | 40 | Tunnels, L2VPN, IPsec |
| Wireless | 12 | Wireless LANs and links |
| Extras | 45 | Tags, custom fields, webhooks |
| Core | 8 | Data sources, jobs |
| Users | 24 | Users, groups, permissions, owners |
| Branching* | 16 | Branch management (plugin) |

\* Requires [netbox-branching](https://github.com/netboxlabs/netbox-branching) plugin

## Resources

- [PowerNetbox on PSGallery](https://www.powershellgallery.com/packages/PowerNetbox)
- [GitHub Repository](https://github.com/ctrl-alt-automate/PowerNetbox)
- [Netbox Documentation](https://netbox.readthedocs.io/)
- [Report Issues](https://github.com/ctrl-alt-automate/PowerNetbox/issues)
