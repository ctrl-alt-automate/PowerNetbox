---
title: Reference
---

# Reference

PowerNetbox provides ~508 cmdlets organized by NetBox module. Each cmdlet has a dedicated page with synopsis, syntax, parameters, examples, and a "Since v..." badge indicating the release that introduced it.

## Naming convention

All cmdlets follow `[Verb]-NB[Module][Resource]`:

| Verb | Action | HTTP method | Example |
|---|---|---|---|
| `Get-` | Retrieve | GET | `Get-NBDCIMDevice` |
| `New-` | Create | POST | `New-NBIPAMAddress` |
| `Set-` | Update | PATCH | `Set-NBVirtualMachine` |
| `Remove-` | Delete | DELETE | `Remove-NBDCIMSite` |

The `NB` prefix avoids collisions with other modules. The `[Module][Resource]` segment mirrors NetBox's URL path: `/api/dcim/devices/` <-> `Get-NBDCIMDevice`.

For deeper conventions (parameter naming, `[Nullable[T]]` clearing pattern, ValidateSet drift), see [Architecture - Parameter conventions](../architecture/parameter-conventions.md).

## Quick links

Most-used cmdlets to bookmark:

- [`Connect-NBAPI`](Setup/Connect-NBAPI.md) -- establish a session, must run first
- [`Get-NBDCIMDevice`](DCIM/Devices/Get-NBDCIMDevice.md) -- query devices (use `-Brief` for fast lookups)
- [`New-NBDCIMDevice`](DCIM/Devices/New-NBDCIMDevice.md) -- create a device
- [`Get-NBIPAMAddress`](IPAM/Address/Get-NBIPAMAddress.md) -- query IP addresses
- [`New-NBIPAMAddress`](IPAM/Address/New-NBIPAMAddress.md) -- allocate a new IP
- [`Get-NBIPAMPrefix`](IPAM/Prefix/Get-NBIPAMPrefix.md) -- query prefixes
- [`Invoke-NBGraphQL`](Setup/Invoke-NBGraphQL.md) -- run a GraphQL query (NetBox 4.5+)
- [`Wait-NBBranch`](Plugins/Branching/Branch/Wait-NBBranch.md) -- block until a netbox-branching branch reaches a target status

## Common parameters

Most cmdlets share a small set of parameters (`-Raw`, `-All`, `-PageSize`, `-Brief`, `-Fields`, `-Omit`, and bulk-operation parameters). They're documented once at [Common parameters](common-parameters.md) and included on every cmdlet page via collapsible blocks.

## All modules

| Module | Endpoints | Cmdlets | Highlights |
|---|---:|---:|---|
| [DCIM](DCIM/index.md) | 45 | 180 | Devices, Sites, Cables, Interfaces, Racks |
| [IPAM](IPAM/index.md) | 18 | 72 | IP Addresses, Prefixes, VLANs, VRFs |
| [Virtualization](Virtualization/index.md) | 5 | 20 | Virtual Machines, Clusters, Interfaces |
| [Circuits](Circuits/index.md) | 11 | 44 | Providers, Circuits, Terminations |
| [Tenancy](Tenancy/index.md) | 5 | 20 | Tenants, Tenant Groups, Contacts |
| [VPN](VPN/index.md) | 10 | 40 | Tunnels, IKE, IPSec |
| [Wireless](Wireless/index.md) | 3 | 12 | LANs, Links |
| [Extras](Extras/index.md) | 12 | 45 | Custom Fields, Tags, Webhooks, Saved Filters |
| [Users](Users/index.md) | 4 | 16 | Users, Groups, Permissions, Tokens |
| [Core](Core/index.md) | 5 | 8 | API Definition, Object Types, Branching |
