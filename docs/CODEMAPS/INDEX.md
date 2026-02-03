# PowerNetbox Architecture

This document provides an architectural overview of the PowerNetbox module.

## Module Structure

```
PowerNetbox/
├── PowerNetbox.psd1          # Module manifest (defines exports, version, dependencies)
├── PowerNetbox.psm1          # Module loader (dot-sources all function files)
├── deploy.ps1                # Build script (dev/prod modes)
├── Functions/                # All PowerShell functions
│   ├── Setup/                # Connection and configuration
│   ├── Helpers/              # Internal utilities (not exported in prod)
│   ├── DCIM/                 # Data Center Infrastructure Management
│   ├── IPAM/                 # IP Address Management
│   ├── Virtualization/       # VMs and clusters
│   ├── Circuits/             # Circuits and providers
│   ├── Tenancy/              # Tenants and contacts
│   ├── VPN/                  # VPN tunnels and IPsec
│   ├── Wireless/             # Wireless LANs
│   ├── Extras/               # Tags, webhooks, custom fields
│   ├── Core/                 # Data sources, jobs
│   ├── Users/                # Users, groups, permissions
│   └── Plugins/              # Plugin support (Branching)
├── Tests/                    # Pester test suite
└── docs/                     # Documentation
```

## Function Count by Module

| Module | Functions | Description |
|--------|-----------|-------------|
| DCIM | 180 | Sites, devices, racks, cables, interfaces, power |
| IPAM | 73 | IP addresses, prefixes, VLANs, VRFs, ASNs |
| Extras | 45 | Tags, webhooks, custom fields, journals |
| Circuits | 44 | Circuits, providers, terminations |
| VPN | 40 | Tunnels, L2VPN, IKE/IPsec policies |
| Setup | 25 | Connection, credentials, configuration |
| Users | 24 | Users, groups, permissions, owners |
| Virtualization | 20 | VMs, clusters, VM interfaces |
| Tenancy | 20 | Tenants, contacts, contact roles |
| Helpers | 18 | Internal utilities (URI building, API calls) |
| Plugins/Branching | 14 | Branch management (netbox-branching) |
| Wireless | 12 | Wireless LANs, wireless links |
| Core | 8 | Data sources, jobs, object types |
| **Total** | **523** | |

## Key Architectural Decisions

### 1. One Function Per File

Every public function lives in its own `.ps1` file, named identically to the function. This enables:
- Easy navigation and discovery
- Simple git blame/history
- Parallel development without merge conflicts

### 2. Centralized Error Handling

All API errors are handled in `InvokeNetboxRequest.ps1`. Individual API functions do **not** have try/catch blocks. This provides:
- Consistent error messages across 500+ functions
- Centralized retry logic with exponential backoff
- Cross-platform error body extraction

**Exceptions** (11 functions with local error handling):
- Feature detection: `Test-NBBranchingAvailable`, `Test-NBAuthentication`
- Resource cleanup: `Invoke-NBInBranch` (try/finally)
- Setup/config: `Connect-NBAPI`, SSL functions

### 3. Naming Convention

```
[Verb]-NB[Module][Resource]
```

| Verb | HTTP Method | Example |
|------|-------------|---------|
| Get- | GET | `Get-NBDCIMDevice` |
| New- | POST | `New-NBIPAMAddress` |
| Set- | PATCH | `Set-NBVirtualMachine` |
| Remove- | DELETE | `Remove-NBDCIMSite` |

### 4. Pipeline Support

All functions support PowerShell pipeline:
- `ValueFromPipelineByPropertyName` on `Id` parameters
- `process {}` blocks for streaming
- Bulk operations via `-InputObject` parameter

### 5. Build Modes

| Mode | Command | Exports |
|------|---------|---------|
| Development | `./deploy.ps1 -Environment dev` | All functions including helpers |
| Production | `./deploy.ps1 -Environment prod` | Only functions with `-` in name |

## Request Flow

```
User Command
    │
    ▼
Get-NBDCIMDevice -Name "server01"
    │
    ▼
BuildURIComponents()          # Convert parameters to URI/body
    │
    ▼
BuildNewURI()                 # Construct full API URL
    │
    ▼
InvokeNetboxRequest()         # Execute HTTP request
    │                              ├─ Get-NBRequestHeaders()  # Auth + branch context
    │                              ├─ Invoke-RestMethod
    │                              └─ Error handling + retry
    ▼
Return results (or -Raw JSON)
```

## Related Documentation

- [Functions by Module](Functions.md) - Detailed function listing
- [Helpers Reference](Helpers.md) - Internal helper functions
- [Getting Started](../guides/Getting-Started.md) - Installation and usage
