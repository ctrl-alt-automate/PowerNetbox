# PowerNetbox Architecture

> Last updated: 2026-02-10

This document provides an architectural overview of the PowerNetbox module.

## Module Structure

```
PowerNetbox/
├── PowerNetbox.psd1          # Module manifest (defines exports, version, dependencies)
├── PowerNetbox.psm1          # Module loader (dot-sources all function files)
├── deploy.ps1                # Build script (dev/prod modes)
├── Functions/                # All PowerShell functions (522 files)
│   ├── Setup/                # Connection and configuration (19 + 6 support)
│   ├── Helpers/              # Internal utilities (16 files, not exported in prod)
│   ├── DCIM/                 # Data Center Infrastructure Management
│   ├── IPAM/                 # IP Address Management
│   ├── Virtualization/       # VMs and clusters
│   ├── Circuits/             # Circuits and providers
│   ├── Tenancy/              # Tenants and contacts
│   ├── VPN/                  # VPN tunnels and IPsec
│   ├── Wireless/             # Wireless LANs
│   ├── Extras/               # Tags, webhooks, custom fields, images
│   ├── Core/                 # Data sources, jobs
│   ├── Users/                # Users, groups, permissions
│   └── Plugins/              # Plugin support (Branching)
├── Tests/                    # Pester test suite (34 files)
└── docs/                     # Documentation (12 guides + codemaps)
```

## Function Count by Module

| Module | Files | Description |
|--------|-------|-------------|
| DCIM | 180 | Sites, devices, racks, cables, interfaces, power |
| IPAM | 73 | IP addresses, prefixes, VLANs, VRFs, ASNs |
| Extras | 46 | Tags, webhooks, custom fields, journals, images |
| Circuits | 44 | Circuits, providers, terminations |
| VPN | 40 | Tunnels, L2VPN, IKE/IPsec policies |
| Setup | 25 | Connection, credentials, configuration (19 main + 6 support) |
| Users | 24 | Users, groups, permissions, owners |
| Virtualization | 20 | VMs, clusters, VM interfaces |
| Tenancy | 20 | Tenants, contacts, contact roles |
| Helpers | 16 | Internal utilities (13 functions + 3 support files) |
| Plugins/Branching | 14 | Branch management (netbox-branching) |
| Wireless | 12 | Wireless LANs, wireless links |
| Core | 8 | Data sources, jobs, object types |
| **Total** | **522** | **518 exported in manifest** |

## Key Architectural Decisions

### 1. One Function Per File

Every public function lives in its own `.ps1` file, named identically to the function. This enables:
- Easy navigation and discovery
- Simple git blame/history
- Parallel development without merge conflicts

### 2. Centralized Error Handling

All API errors are handled in `InvokeNetboxRequest.ps1`. Individual API functions do **not** have try/catch blocks. This provides:
- Consistent error messages across 500+ functions
- Centralized retry logic with exponential backoff (408, 429, 5xx)
- Cross-platform error body extraction (Desktop vs Core PowerShell)
- Sensitive field redaction in verbose logging (secret, password, key, token, psk)

**Exceptions** (11 functions with local error handling):
- Feature detection: `Test-NBBranchingAvailable`, `Test-NBAuthentication` (return bool)
- Resource cleanup: `Invoke-NBInBranch` (try/finally for context restoration)
- Setup/config: `Connect-NBAPI`, SSL functions (special initialization)
- Helpers: `ConvertTo-NetboxVersion` (safe parsing with null fallback)

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
- Bulk operations via `-InputObject` parameter and `Send-NBBulkRequest`

### 5. Build Modes

| Mode | Command | Exports |
|------|---------|---------|
| Development | `./deploy.ps1 -Environment dev` | All functions including helpers |
| Production | `./deploy.ps1 -Environment prod` | Only functions with `-` in name |

### 6. Parameter Set Pattern

All Get functions use standardized parameter sets:
- **ByID**: Direct resource access by ID (no pagination, returns single object)
- **Query**: Filtered searches (supports `-All` pagination, `-Brief`, `-Fields`, `-Omit`)

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
    │                              ├─ Pagination (-All loop)
    │                              └─ Error handling + retry
    ▼
Return results (or -Raw JSON)
```

## Module Config State

```powershell
$script:NetboxConfig = @{
    Connected     = $false
    Hostname      = $null
    Credential    = $null           # PSCredential (token in password)
    HostScheme    = $null           # 'https' or 'http'
    HostPort      = $null
    InvokeParams  = $null           # Extra Invoke-RestMethod params
    Timeout       = $null           # Request timeout in seconds
    NetboxVersion = $null           # Raw version string from API
    ParsedVersion = $null           # [System.Version] for comparisons
    BranchStack   = [Stack[object]] # Branch context stack (Enter/Exit-NBBranch)
}
```

## Test Coverage

| Category | Files | Tests | Description |
|----------|-------|-------|-------------|
| Unit | 24 | ~2,350 | Module-specific + infrastructure tests |
| Scenario | 4 | 112 | End-to-end workflows (Filters, Relationships, Bulk, Workflows) |
| Integration | 3 | 94 | Live API tests against 3 Netbox versions (4.3.7, 4.4.10, 4.5.2) |
| Quality | 1 | ~50 | Structural quality checks (CodeQuality.Tests.ps1) |

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| test.yml | Push/PR to dev/main | Unit tests (Ubuntu + Windows PS 7, Windows PS 5.1) |
| pssa.yml | Push/PR | PSScriptAnalyzer linting |
| integration.yml | Push to dev/main/beta, weekly | Integration tests (3 Netbox versions via Docker) |
| compatibility.yml | Push to compat branches, weekly | Multi-version compatibility matrix |
| branching-integration.yml | Branching file changes | Branching plugin tests |
| pre-release-validation.yml | Manual | Full pre-release validation suite |
| release.yml | Release tag | PSGallery publish |

**Optimizations**: Module caching via `actions/cache@v4`; integration tests excluded from PR triggers.

## Related Documentation

- [Functions by Module](Functions.md) - Detailed function listing
- [Helpers Reference](Helpers.md) - Internal helper functions
- [Getting Started](../guides/Getting-Started.md) - Installation and usage
