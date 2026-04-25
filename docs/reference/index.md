---
title: Reference
---

# Reference

PowerNetbox provides approximately 508 cmdlets organized by NetBox module. Each
cmdlet has a dedicated reference page with synopsis, syntax, parameters, examples,
and a "Since v..." badge indicating the version that introduced it.

## Modules

| Module | Endpoints | Cmdlets | Highlights |
|---|---:|---:|---|
| [DCIM](DCIM/Devices/Get-NBDCIMDevice.md) | 45 | 180 | Devices, Sites, Cables, Interfaces, Racks |
| [IPAM](IPAM/Address/Get-NBIPAMAddress.md) | 18 | 72 | IP Addresses, Prefixes, VLANs, VRFs |
| [Virtualization](Virtualization/) | 5 | 20 | Virtual Machines, Clusters, Interfaces |
| [Circuits](Circuits/) | 11 | 44 | Providers, Circuits, Terminations |
| [Tenancy](Tenancy/) | 5 | 20 | Tenants, Tenant Groups, Contacts |
| [VPN](VPN/) | 10 | 40 | Tunnels, IKE, IPSec |
| [Wireless](Wireless/) | 3 | 12 | LANs, Links |
| [Extras](Extras/) | 12 | 45 | Custom Fields, Tags, Webhooks, Saved Filters |
| [Users](Users/) | 4 | 16 | Users, Groups, Permissions, Tokens |
| [Core](Core/) | 5 | 8 | API Definition, Object Types |

!!! note "Per-module landing pages"
    The DCIM and IPAM links above point at representative cmdlets. Per-module
    landing pages with full cmdlet listings are planned for a future release.

## Conventions

All cmdlets follow the naming pattern `[Verb]-NB[Module][Resource]`. See
[Architecture -- Parameter conventions](../architecture/parameter-conventions.md)
for the patterns shared across the codebase: snake_case parameter names, Nullable
FK clearing, empty-string sentinels, ValidateSet drift prevention, and the
ASCII-only `.ps1` constraint.

For parameters shared across most cmdlets (`-Raw`, `-All`, `-PageSize`, `-Brief`,
`-Fields`, `-Omit`, `-InputObject`, `-BatchSize`, `-Force`), see
[Common parameters](common-parameters.md).

## Special cmdlets

- [`Connect-NBAPI`](Setup/Connect-NBAPI.md) -- Establish a connection to a NetBox
  instance. Run once per session; all other cmdlets inherit the context it sets.

- [`Invoke-NBGraphQL`](Setup/Invoke-NBGraphQL.md) -- Execute a GraphQL query against
  NetBox 4.5+. Returns raw GraphQL response objects.

- [`Wait-NBBranch`](Plugins/Branching/Branch/Wait-NBBranch.md) -- Block until a
  branch reaches a target status (`ready`, `merged`, or `archived`). Added in
  v4.5.7.0. Useful for scripting branch workflows:

  ```powershell
  New-NBBranch -Name "deployment-2026-05" | Wait-NBBranch | Enter-NBBranch
  ```

## Branching plugin

The `Plugins/Branching/` section covers the 16 cmdlets that wrap the
[netbox-branching](https://github.com/netboxlabs/netbox-branching) plugin. These
cmdlets are available only when the plugin is installed on the target NetBox
instance. Use `Test-NBBranchingAvailable` to probe availability at runtime.
