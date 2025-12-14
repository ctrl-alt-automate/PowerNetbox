# CLAUDE.md - PowerNetbox Development Guide

This file provides guidance to Claude Code (or any AI assistant) when working with this codebase.

## Project Overview

**PowerNetbox** is a PowerShell module that provides a wrapper for the [Netbox](https://github.com/netbox-community/netbox) REST API. It allows users to interact with Netbox infrastructure management directly from PowerShell.

> **Note:** This is a fork of [NetboxPS](https://github.com/benclaussen/NetboxPS) published under a new name to provide full Netbox 4.x compatibility.

- **Module Name**: PowerNetbox (PSGallery)
- **Current Version**: 4.4.8.1
- **Target Netbox Version**: 4.4.8 (fully compatible)
- **Minimum Netbox Version**: 2.8.x
- **PowerShell Version**: 5.1+ (Desktop and Core editions)
- **Original Repository**: https://github.com/benclaussen/NetboxPS
- **Fork Repository**: https://github.com/ctrl-alt-automate/PowerNetbox
- **Issue Tracking**: https://github.com/ctrl-alt-automate/PowerNetbox/issues
- **Total Functions**: 494 public functions across all modules

## Development Environment

### Quick Connect (Recommended)
```powershell
# One-liner to build, import, and connect
./deploy.ps1 -Environment dev -SkipVersion; . ./Connect-DevNetbox.ps1
```

### Configuration Setup
Configuration is stored in `.netboxps.config.ps1` (gitignored):
```powershell
# First time setup - copy example and edit with your credentials
Copy-Item .netboxps.config.example.ps1 .netboxps.config.ps1

# Then connect using the helper script
. ./Connect-DevNetbox.ps1
```

### Manual Connection
```powershell
# Load config manually
$config = & ./.netboxps.config.ps1
$cred = [PSCredential]::new('api', (ConvertTo-SecureString $config.Token -AsPlainText -Force))
Connect-NBAPI -Hostname $config.Hostname -Credential $cred
```

### Building the Module
```powershell
# Requires PSScriptAnalyzer module
Install-Module PSScriptAnalyzer -Scope CurrentUser

# Build for development (exports all functions including helpers)
./deploy.ps1 -Environment dev -SkipVersion

# Build for production (exports only public functions with '-' in name)
./deploy.ps1 -Environment prod

# Build and reimport in current session
./deploy.ps1 -Environment dev -ResetCurrentEnvironment
```

The build process:
1. Runs PSScriptAnalyzer to fix whitespace issues
2. Concatenates all `.ps1` files from `Functions/` into a single module
3. Updates version in manifest
4. Outputs to `PowerNetbox/` directory

### Running Tests
```powershell
# Run all Pester tests
Invoke-Pester ./Tests/

# Run specific test file
Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1

# Run integration tests (mock responses)
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Integration'

# Run live integration tests (requires Netbox instance)
$env:NETBOX_HOST = 'your-netbox-host.com'
$env:NETBOX_TOKEN = 'your-api-token'
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Live'
```

### CI/CD Workflows
The project uses GitHub Actions for CI/CD:
- **Lint**: PSScriptAnalyzer runs on push/PR to check code quality
- **Test**: Pester tests run on ubuntu, windows, and macos
- **Release**: Tests must pass before PSGallery publish

## GitHub Wiki

The project documentation is maintained in a separate wiki repository.

### Wiki Location
- **Local**: `/Users/elvis/Developer/work/PowerNetbox.wiki/`
- **Remote**: `https://github.com/ctrl-alt-automate/PowerNetbox.wiki.git`
- **Web**: `https://github.com/ctrl-alt-automate/PowerNetbox/wiki`

### Working with the Wiki
```bash
# Clone wiki (if not already cloned)
cd /Users/elvis/Developer/work
git clone https://github.com/ctrl-alt-automate/PowerNetbox.wiki.git

# Edit and push changes (note: GitHub wiki uses 'master' branch)
cd PowerNetbox.wiki
# ... edit markdown files ...
git add . && git commit -m "Update docs" && git push origin main:master
```

### Wiki Structure
| File | Purpose |
|------|---------|
| `Home.md` | Landing page (shown first) |
| `_Sidebar.md` | Navigation sidebar |
| `_Footer.md` | Footer on all pages |
| `Getting-Started.md` | Installation and quick start |
| `Common-Workflows.md` | Use cases, VMware PowerCLI integration |
| `DCIM-Examples.md` | Sites, devices, racks, cables |
| `IPAM-Examples.md` | IP addresses, prefixes, VLANs |
| `Function-Naming.md` | Naming conventions reference |
| `Troubleshooting.md` | Common issues and solutions |

## Project Structure

```
PowerNetbox/                           # Module output directory
├── PowerNetbox.psd1               # Built manifest
└── PowerNetbox.psm1               # Built module

PowerNetbox.wiki/                     # GitHub Wiki (separate repo)
├── Home.md                        # Landing page
├── _Sidebar.md                    # Navigation
├── Getting-Started.md             # Quick start guide
├── Common-Workflows.md            # Use cases and examples
└── Troubleshooting.md             # Common issues

NetboxPS/                             # Repository root
├── Functions/                    # Source files - one function per file (489 functions)
│   ├── Circuits/                 # Circuit management (100% coverage)
│   │   ├── Circuits/             # Get/New/Set/Remove
│   │   ├── CircuitGroups/        # Get/New/Set/Remove
│   │   ├── CircuitGroupAssignments/
│   │   ├── Providers/            # Get/New/Set/Remove
│   │   ├── ProviderAccounts/     # Get/New/Set/Remove
│   │   ├── ProviderNetworks/     # Get/New/Set/Remove
│   │   ├── Terminations/         # Get/New/Set/Remove
│   │   ├── Types/                # Get/New/Set/Remove
│   │   ├── VirtualCircuits/      # Get/New/Set/Remove
│   │   ├── VirtualCircuitTypes/  # Get/New/Set/Remove
│   │   └── VirtualCircuitTerminations/
│   ├── DCIM/                     # Data Center Infrastructure (100% coverage)
│   │   ├── Cables/               # Get/New/Set/Remove
│   │   ├── CableTerminations/    # Get
│   │   ├── ConnectedDevice/      # Get
│   │   ├── ConsolePorts/         # Get/New/Set/Remove
│   │   ├── ConsolePortTemplates/ # Get/New/Set/Remove
│   │   ├── ConsoleServerPorts/   # Get/New/Set/Remove
│   │   ├── ConsoleServerPortTemplates/
│   │   ├── DeviceBays/           # Get/New/Set/Remove
│   │   ├── DeviceBayTemplates/   # Get/New/Set/Remove
│   │   ├── Devices/              # Get/New/Set/Remove + Roles/Types
│   │   ├── FrontPorts/           # Get/Add/Set/Remove
│   │   ├── FrontPortTemplates/   # Get/New/Set/Remove
│   │   ├── Interfaces/           # Get/Add/Set/Remove
│   │   ├── InterfaceTemplates/   # Get/New/Set/Remove
│   │   ├── InventoryItems/       # Get/New/Set/Remove
│   │   ├── InventoryItemRoles/   # Get/New/Set/Remove
│   │   ├── InventoryItemTemplates/
│   │   ├── Locations/            # Get/New/Set/Remove
│   │   ├── MACAddresses/         # Get/New/Set/Remove
│   │   ├── Manufacturers/        # Get/New/Set/Remove
│   │   ├── Modules/              # Get/New/Set/Remove
│   │   ├── ModuleBays/           # Get/New/Set/Remove
│   │   ├── ModuleBayTemplates/   # Get/New/Set/Remove
│   │   ├── ModuleTypes/          # Get/New/Set/Remove
│   │   ├── ModuleTypeProfiles/   # Get/New/Set/Remove
│   │   ├── Platforms/            # Get/New/Set/Remove
│   │   ├── PowerFeeds/           # Get/New/Set/Remove
│   │   ├── PowerOutlets/         # Get/New/Set/Remove
│   │   ├── PowerOutletTemplates/ # Get/New/Set/Remove
│   │   ├── PowerPanels/          # Get/New/Set/Remove
│   │   ├── PowerPorts/           # Get/New/Set/Remove
│   │   ├── PowerPortTemplates/   # Get/New/Set/Remove
│   │   ├── Racks/                # Get/New/Set/Remove
│   │   ├── RackReservations/     # Get/New/Set/Remove
│   │   ├── RackRoles/            # Get/New/Set/Remove
│   │   ├── RackTypes/            # Get/New/Set/Remove
│   │   ├── RearPorts/            # Get/Add/Set/Remove
│   │   ├── RearPortTemplates/    # Get/New/Set/Remove
│   │   ├── Regions/              # Get/New/Set/Remove
│   │   ├── SiteGroups/           # Get/New/Set/Remove
│   │   ├── Sites/                # Get/New/Set/Remove
│   │   ├── VirtualChassis/       # Get/New/Set/Remove
│   │   └── VirtualDeviceContexts/# Get/New/Set/Remove
│   ├── Extras/                   # Tags, custom fields, etc. (expanded)
│   │   ├── Bookmarks/            # Get/New/Remove
│   │   ├── ConfigContexts/       # Get/New/Set/Remove
│   │   ├── CustomFieldChoiceSets/# Get/New/Set/Remove
│   │   ├── CustomFields/         # Get/New/Set/Remove
│   │   ├── CustomLinks/          # Get/New/Set/Remove
│   │   ├── EventRules/           # Get/New/Set/Remove
│   │   ├── ExportTemplates/      # Get/New/Set/Remove
│   │   ├── ImageAttachments/     # Get/Remove
│   │   ├── JournalEntries/       # Get/New/Set/Remove
│   │   ├── SavedFilters/         # Get/New/Set/Remove
│   │   ├── Tags/                 # Get/New/Set/Remove
│   │   └── Webhooks/             # Get/New/Set/Remove
│   ├── Helpers/                  # Internal helper functions
│   ├── IPAM/                     # IP Address Management (100% coverage)
│   │   ├── Address/              # Get/New/Set/Remove + AvailableIP
│   │   ├── Aggregate/            # Get/New/Set/Remove
│   │   ├── ASN/                  # Get/New/Set/Remove
│   │   ├── ASNRange/             # Get/New/Set/Remove
│   │   ├── FHRPGroup/            # Get/New/Set/Remove
│   │   ├── FHRPGroupAssignment/  # Get/New/Set/Remove
│   │   ├── Prefix/               # Get/New/Set/Remove
│   │   ├── Range/                # Get/New/Set/Remove
│   │   ├── RIR/                  # Get/New/Set/Remove
│   │   ├── Role/                 # Get/New/Set/Remove
│   │   ├── RouteTarget/          # Get/New/Set/Remove
│   │   ├── Service/              # Get/New/Set/Remove
│   │   ├── ServiceTemplate/      # Get/New/Set/Remove
│   │   ├── VLAN/                 # Get/New/Set/Remove
│   │   ├── VLANGroup/            # Get/New/Set/Remove
│   │   ├── VLANTranslationPolicy/# Get/New/Set/Remove
│   │   ├── VLANTranslationRule/  # Get/New/Set/Remove
│   │   └── VRF/                  # Get/New/Set/Remove
│   ├── Setup/                    # Connection and configuration
│   │   └── Support/
│   ├── Tenancy/                  # Tenants, contacts
│   ├── Virtualization/           # VMs, clusters
│   ├── VPN/                      # VPN module (NEW)
│   │   ├── IKEPolicy/            # Get/New/Set/Remove
│   │   ├── IKEProposal/          # Get/New/Set/Remove
│   │   ├── IPSecPolicy/          # Get/New/Set/Remove
│   │   ├── IPSecProfile/         # Get/New/Set/Remove
│   │   ├── IPSecProposal/        # Get/New/Set/Remove
│   │   ├── L2VPN/                # Get/New/Set/Remove
│   │   ├── L2VPNTermination/     # Get/New/Set/Remove
│   │   ├── Tunnel/               # Get/New/Set/Remove
│   │   ├── TunnelGroup/          # Get/New/Set/Remove
│   │   └── TunnelTermination/    # Get/New/Set/Remove
│   ├── Wireless/                 # Wireless module
│   │   ├── WirelessLAN/          # Get/New/Set/Remove
│   │   ├── WirelessLANGroup/     # Get/New/Set/Remove
│   │   └── WirelessLink/         # Get/New/Set/Remove
│   ├── Core/                     # Core module (NEW)
│   │   ├── DataFiles/            # Get
│   │   ├── DataSources/          # Get/New/Set/Remove
│   │   ├── Jobs/                 # Get
│   │   ├── ObjectChanges/        # Get
│   │   └── ObjectTypes/          # Get
│   ├── Users/                    # Users module (NEW)
│   │   ├── Groups/               # Get/New/Set/Remove
│   │   ├── Permissions/          # Get/New/Set/Remove
│   │   ├── Tokens/               # Get/New/Set/Remove
│   │   └── Users/                # Get/New/Set/Remove
│   └── Plugins/                  # Plugin modules
│       └── Branching/            # netbox-branching plugin support
│           ├── Branch/           # Get/New/Set/Remove + Sync/Merge/Undo
│           ├── BranchEvent/      # Get
│           ├── ChangeDiff/       # Get
│           └── Context/          # Enter/Exit/Get-NBBranchContext + helpers
├── Tests/                        # Pester tests
├── .claude/commands/             # Specialized AI agent prompts
├── PowerNetbox/                   # Build output directory
├── PowerNetbox.psd1               # Module manifest (source)
├── PowerNetbox.psm1               # Root module file (source)
├── Connect-DevNetbox.ps1         # Quick connect helper script
└── deploy.ps1                    # Build script
```

## Function Naming Convention

Functions follow this pattern: `[Verb]-NB[Module][Resource]`

| Verb | Purpose | HTTP Method |
|------|---------|-------------|
| `Get-` | Retrieve resources | GET |
| `New-` | Create resources | POST |
| `Set-` | Update resources | PATCH |
| `Remove-` | Delete resources | DELETE |
| `Add-` | Create child resources (legacy, prefer `New-`) | POST |

Examples:
- `Get-NBDCIMDevice` - Get devices from DCIM module
- `New-NBIPAMAddress` - Create new IP address
- `Set-NBVirtualMachine` - Update a virtual machine
- `Remove-NBDCIMSite` - Delete a site

## Creating New Functions

### Template for GET Function
```powershell
function Get-NB[Module][Resource] {
    [CmdletBinding()]
    param (
        [uint16]$Limit,
        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,
        # Add other filter parameters based on API schema

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('[module]', '[resource]'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw
    }
}
```

### Template for NEW Function
```powershell
function New-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        # Add required and optional parameters

        [hashtable]$Custom_Fields,
        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('[module]', '[resource]'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        if ($PSCmdlet.ShouldProcess($Name, 'Create [Resource]')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
```

### Template for SET Function
```powershell
function Set-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,
        # Add updateable parameters

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('[module]', '[resource]', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update [Resource]')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
```

### Template for REMOVE Function
```powershell
function Remove-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('[module]', '[resource]', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete [Resource]')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
```

## Bulk Operations

PowerNetbox supports high-performance bulk operations for creating, updating, and deleting multiple resources in a single API call. This significantly improves performance when working with large datasets.

### Supported Bulk Operations

| Function | Mode | HTTP Method | Description |
|----------|------|-------------|-------------|
| `New-NBDCIMDevice` | POST | POST | Create multiple devices |
| `New-NBDCIMInterface` | POST | POST | Create multiple interfaces |
| `New-NBIPAMAddress` | POST | POST | Create multiple IP addresses |
| `New-NBIPAMPrefix` | POST | POST | Create multiple prefixes |
| `New-NBIPAMVLAN` | POST | POST | Create multiple VLANs |
| `New-NBVirtualMachine` | POST | POST | Create multiple VMs |
| `New-NBVirtualMachineInterface` | POST | POST | Create multiple VM interfaces |
| `Set-NBDCIMDevice` | PATCH | PATCH | Update multiple devices |
| `Remove-NBDCIMDevice` | DELETE | DELETE | Delete multiple devices |

### Bulk Operation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-InputObject` | PSCustomObject | - | Pipeline input for bulk mode |
| `-BatchSize` | int | 50 | Items per API request (1-1000) |
| `-Force` | switch | - | Skip confirmation prompts |

### Usage Examples

```powershell
# Bulk create devices
$devices = 1..100 | ForEach-Object {
    [PSCustomObject]@{
        Name = "server-$_"
        Role = 1
        Device_Type = 1
        Site = 1
        Status = "planned"
    }
}
$devices | New-NBDCIMDevice -BatchSize 50 -Force

# Bulk update devices
$updates = Get-NBDCIMDevice -Status "planned" | ForEach-Object {
    [PSCustomObject]@{
        Id = $_.id
        Status = "active"
        Comments = "Deployed $(Get-Date -Format 'yyyy-MM-dd')"
    }
}
$updates | Set-NBDCIMDevice -BatchSize 50 -Force

# Bulk delete devices
Get-NBDCIMDevice -Status "decommissioning" | Remove-NBDCIMDevice -BatchSize 50 -Force

# Import from CSV
Import-Csv ./vlans.csv | New-NBIPAMVLAN -BatchSize 100 -Force
```

### Bulk Operation Internals

Bulk operations use two helper components:

1. **`BulkOperationResult`** class - Tracks success/failure of bulk operations
   - Properties: `Succeeded`, `Failed`, `HasErrors`, `TotalCount`, `SuccessCount`, `FailedCount`
   - Methods: `AddSuccess()`, `AddFailure()`, `GetSummary()`

2. **`Send-NBBulkRequest`** function - Handles batching and API calls
   - Splits items into batches based on `BatchSize`
   - Shows progress bar with `-ShowProgress`
   - Returns `BulkOperationResult` object

### Template for Bulk-Enabled NEW Function
```powershell
function New-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low', DefaultParameterSetName = 'Single')]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [string]$Name,
        # ... other single mode params ...

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 50,

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Force,

        [Parameter()]
        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('[module]', '[resource]'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Single mode - immediate API call
            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
            if ($PSCmdlet.ShouldProcess($Name, 'Create [Resource]')) {
                InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $item[$key] = $prop.Value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) [resource](s)"
            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create [resources] (bulk)')) {
                $result = Send-NBBulkRequest -URI $URI -Items $bulkItems.ToArray() -Method POST `
                    -BatchSize $BatchSize -ShowProgress -ActivityName 'Creating [resources]'

                foreach ($item in $result.Succeeded) { Write-Output $item }
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed: $($failure.Error)" -TargetObject $failure.Item
                }
                if ($result.HasErrors) { Write-Warning $result.GetSummary() }
            }
        }
    }
}
```

## Key Helper Functions

### `BuildNewURI`
Constructs the full API URI from segments and parameters.
```powershell
$URI = BuildNewURI -Segments @('dcim', 'devices') -Parameters @{name='server01'}
# Result: https://netbox.example.com/api/dcim/devices/?name=server01
```

### `BuildURIComponents`
Processes PSBoundParameters into URI segments and query/body parameters.
```powershell
$URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
```

### `InvokeNetboxRequest`
Executes the actual REST API call with authentication.
```powershell
InvokeNetboxRequest -URI $URI -Method GET -Raw:$Raw
InvokeNetboxRequest -URI $URI -Method POST -Body $bodyHashtable
```

## API Module Mapping

| PowerShell Module | API Path | Status |
|-------------------|----------|--------|
| Setup | `/api/status/` | ✅ Implemented |
| DCIM | `/api/dcim/` | ✅ **Full** (45 endpoints, 180 functions) |
| IPAM | `/api/ipam/` | ✅ **Full** (18 endpoints, 72 functions) |
| Virtualization | `/api/virtualization/` | ✅ **Full** (5 endpoints, 20 functions) |
| Tenancy | `/api/tenancy/` | ✅ **Full** (5 endpoints, 20 functions) |
| Circuits | `/api/circuits/` | ✅ **Full** (11 endpoints, 44 functions) |
| Extras | `/api/extras/` | ✅ **Expanded** (12 endpoints, 45 functions) |
| VPN | `/api/vpn/` | ✅ **Full** (10 endpoints, 40 functions) |
| Wireless | `/api/wireless/` | ✅ **Full** (3 endpoints, 12 functions) |
| Core | `/api/core/` | ✅ **Full** (5 endpoints, 8 functions) |
| Users | `/api/users/` | ✅ **Full** (4 endpoints, 16 functions) |
| Branching* | `/api/plugins/netbox-branching/` | ✅ **Full** (3 endpoints, 16 functions) |

\* Requires [netbox-branching](https://github.com/netboxlabs/netbox-branching) plugin

## Netbox 4.x Compatibility

### Known Breaking Changes (Fixed)
| Issue | Old Behavior | New Behavior (4.x) | Status |
|-------|--------------|-------------------|--------|
| ContentTypes endpoint | `/api/extras/content-types/` | `/api/core/object-types/` | ✅ Fixed |
| VM Site parameter | Mandatory | Optional (only Name required) | ✅ Fixed |
| Set-NBDCIMSite | Missing | Added | ✅ Fixed |

### API Endpoints Changed in Netbox 4.x
- `/api/extras/content-types/` → `/api/core/object-types/`
- Several fields that were mandatory are now optional
- New modules added: VPN, Wireless

### Testing Against Netbox 4.4.8
All 360 functions tested and working correctly against Netbox 4.4.8.
- **DCIM**: 23 new endpoint types tested (VirtualChassis, VirtualDeviceContext, MACAddress, RackRole, RackType, RackReservation, PowerPanel, PowerFeed, PowerPort, PowerOutlet, ConsolePort, ConsoleServerPort, Module, ModuleType, ModuleBay, DeviceBay, InterfaceTemplate, FrontPortTemplate, RearPortTemplate, InventoryItem, InventoryItemRole, InventoryItemTemplate, ModuleTypeProfile)
- **IPAM**: 14 endpoint types tested (RIR, VLANGroup, FHRPGroup, FHRPGroupAssignment, VLANTranslationPolicy, VLANTranslationRule, ASN, ASNRange, VRF, RouteTarget, Service, ServiceTemplate, Aggregate, Role)
- **VPN**: 10 endpoint types tested (Tunnel, TunnelGroup, TunnelTermination, L2VPN, L2VPNTermination, IKEPolicy, IKEProposal, IPSecPolicy, IPSecProfile, IPSecProposal)
- **Wireless**: 3 endpoint types tested (WirelessLAN, WirelessLANGroup, WirelessLink)
- CRUD operations verified for: RIR, VLANGroup, RackType, RackRole, ModuleTypeProfile, InventoryItemRole

## Roadmap & Issues

See [GitHub Issues](https://github.com/ctrl-alt-automate/PowerNetbox/issues) for the full roadmap:

### Completed
- **v2.0.0**: Netbox 4.x compatibility ✅
- **v2.1.0**: DCIM expansion ✅ (racks, locations, regions, site-groups, manufacturers)
- **v2.2.0**: IPAM expansion ✅ (VRFs, route targets, ASNs, services)
- **v2.3.0**: New modules ✅ (VPN, Wireless)
- **v2.4.0**: 100% DCIM coverage ✅ (issue #11 - 45 endpoints, 180 functions)
- **v2.5.0**: 100% IPAM coverage ✅ (issue #12 - 18 endpoints, 72 functions)
- **Issue #23**: SupportsShouldProcess on New-NB* functions ✅
- **Issue #24**: CI/CD workflow with Pester tests ✅
- **Issue #25**: PSGallery manifest metadata ✅
- **Issue #26**: Export only public functions ✅
- **Issue #27**: Process blocks for pipeline support ✅
- **Issue #28**: Integration tests with mock API ✅
- **Issue #29**: Virtualization module 100% coverage ✅ (11 new functions)
- **Issue #30**: Tenancy module 100% coverage ✅ (9 new functions)

### Completed (Recent)
- **Issue #31**: Circuits module 100% coverage ✅ (11 endpoints, 44 functions)
- **Issue #32**: Extras module expansion ✅ (12 endpoints, 45 functions)
- **Issue #33**: Core module ✅ (5 endpoints, 8 functions)
- **Issue #34**: Users module ✅ (4 endpoints, 16 functions)

### Bulk Operations (Completed)
- **Issue #81**: Bulk operations infrastructure ✅ (BulkOperationResult class, Send-NBBulkRequest helper)
- **Issue #83**: New-NBIPAMAddress bulk mode ✅
- **Issue #84**: New-NBDCIMInterface bulk mode ✅
- **Issue #85**: New-NBIPAMPrefix bulk mode ✅
- **Issue #86**: New-NBVirtualMachine bulk mode ✅
- **Issue #87**: Set-NBDCIMDevice bulk PATCH ✅
- **Issue #88**: Remove-NBDCIMDevice bulk DELETE ✅
- **Issue #89**: New-NBIPAMVLAN bulk mode ✅
- **Issue #90**: New-NBVirtualMachineInterface bulk mode ✅

### Cross-Platform Compatibility (Completed)
- **Issue #35**: Fix path handling in deploy.ps1 ✅
- **Issue #36**: Certificate handling for PS Core ✅
- **Issue #37**: Remove System.Web dependency ✅
- **Issue #38**: Standardize line endings/encoding ✅
- **Issue #39**: StreamReader UTF-8 encoding ✅
- **Issue #40**: Cross-platform documentation ✅

### Testing (Completed)
- **Issue #41**: Pester 5 compatibility ✅
- **Issue #45**: Fix test assertions ✅
- **Issue #46**: ValidateVirtualizationChoice bug fix ✅
- **Issue #53**: Test coverage expansion ✅ (613 tests)

### Test Coverage Roadmap (Issue #53)
Goal: 100% unit test coverage

| Phase | Issue | Module | Status | Tests |
|-------|-------|--------|--------|-------|
| 1 | #45 | Fix existing tests | ✅ Done | 217 fixed |
| 2 | #48 | IPAM completion | ✅ Done | 105 tests |
| 2b | #52 | Virtualization completion | ✅ Done | 61 tests |
| 3 | #49 | Tenancy (new) | ✅ Done | 37 tests |
| 4 | #50 | Circuits (new) | ✅ Done | 69 tests |
| 5 | #51 | Extras (new) | ✅ Done | 77 tests |
| 6 | #47 | DCIM completion | ✅ Done | 205 tests |

**Current coverage**: 654 tests passing (~80% of functions tested)

## Testing API Endpoints

Use curl to quickly test API endpoints:
```bash
# Get API root
curl -s -H "Authorization: Token YOUR_TOKEN" "https://YOUR_HOST/api/" | python3 -m json.tool

# Get specific endpoint schema
curl -s -H "Authorization: Token YOUR_TOKEN" "https://YOUR_HOST/api/dcim/racks/" | python3 -m json.tool

# Check available endpoints for a module
curl -s -H "Authorization: Token YOUR_TOKEN" "https://YOUR_HOST/api/dcim/" | python3 -m json.tool
```

## Code Style Guidelines

- Follow [PowerShell Practice and Style Guidelines](https://poshcode.gitbook.io/powershell-practice-and-style/)
- One function per file
- Use `[CmdletBinding()]` on all functions
- Support `-WhatIf`/`-Confirm` for state-changing operations (`SupportsShouldProcess`)
- Use proper parameter validation attributes (`ValidateSet`, `ValidateRange`, `ValidatePattern`)
- Include pipeline support where appropriate (`ValueFromPipelineByPropertyName`)
- Always include `-Raw` switch to return unprocessed API response
- Use `Write-Verbose` for debug output, never `Write-Host`
- Always use `process {}` blocks for proper pipeline streaming
- Include `[OutputType([PSCustomObject])]` on all functions
- Include comprehensive comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)

### Function Export Policy
- **Production builds**: Only functions with `-` in the name are exported (public API)
- **Development builds**: All functions exported including internal helpers
- Internal helpers (no `-`): `BuildNewURI`, `BuildURIComponents`, `InvokeNetboxRequest`, etc.
- Backwards compatibility aliases maintained for renamed `Add-*` → `New-*` functions

## Bulk Operations (Issue #81)

PowerNetbox supports bulk API operations for improved performance when creating many resources.

### Usage

```powershell
# Single device (backwards compatible)
New-NBDCIMDevice -Name "srv01" -Role 1 -Device_Type 1 -Site 1

# Bulk via pipeline - creates 100 devices in 2 API calls
1..100 | ForEach-Object {
    [PSCustomObject]@{
        Name = "server-$_"
        Role = 1
        Device_Type = 1
        Site = 1
    }
} | New-NBDCIMDevice -BatchSize 50 -Force
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-InputObject` | Pipeline input for bulk mode | - |
| `-BatchSize` | Items per API request (1-1000) | 50 |
| `-Force` | Skip confirmation prompts | $false |

### Helper Functions

| Function | Description |
|----------|-------------|
| `BulkOperationResult` | Class tracking successes, failures, timing |
| `Send-NBBulkRequest` | Internal helper for batched API calls |

### Supported Endpoints

| Endpoint | Bulk Support | Status |
|----------|--------------|--------|
| `New-NBDCIMDevice` | ✅ Full | Implemented |
| Other `New-NB*` | 🔜 Planned | Future PRs |
| `Set-NB*` (bulk PATCH) | 🔜 Planned | Future PRs |
| `Remove-NB*` (bulk DELETE) | 🔜 Planned | Future PRs |

### Implementation Pattern

For adding bulk support to other functions:

```powershell
function New-NB[Module][Resource] {
    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory)]
        [string]$Name,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', ValueFromPipeline, Mandatory)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 50,

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Force
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            [void]$bulkItems.Add($InputObject)
        } else {
            # Single item logic
        }
    }

    end {
        if ($bulkItems.Count -gt 0) {
            Send-NBBulkRequest -URI $URI -Items $bulkItems -Method POST -BatchSize $BatchSize
        }
    }
}
```

## Slash Commands (Specialized Agents)

This project includes specialized slash commands in `.claude/commands/` for different expertise areas:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/netbox-api [endpoint]` | Netbox API expert | Research endpoint schemas, understand API structure |
| `/powershell-expert [question]` | PowerShell best practices | Code review, pattern questions, modern PS guidance |
| `/implement [endpoint]` | Combined implementation workflow | Creating new endpoint functions (uses both experts) |
| `/test-endpoint [function]` | Compatibility testing | Verify functions work against Netbox 4.4.8 |

### Usage Examples
```bash
# Research an API endpoint before implementing
/netbox-api dcim/racks

# Ask about PowerShell patterns
/powershell-expert how should I handle pagination in Get functions?

# Implement a complete new endpoint (recommended workflow)
/implement dcim/locations

# Test an existing function for compatibility
/test-endpoint Get-NBDCIMDevice
```

### Recommended Workflow for New Endpoints

1. **Research first**: Use `/netbox-api [endpoint]` to understand the API schema
2. **Check patterns**: Use `/powershell-expert` if unsure about implementation patterns
3. **Implement**: Use `/implement [endpoint]` for guided implementation
4. **Test**: Use `/test-endpoint` to verify against live Netbox

### Agent Files Location
The agent prompts are stored in `.claude/commands/`:
- `netbox-api.md` - Netbox API expertise context
- `powershell-expert.md` - PowerShell best practices context
- `implement.md` - Combined implementation workflow
- `test-endpoint.md` - Testing workflow

## Git Workflow

- Main development branch: `dev`
- Submit all PRs against `dev` branch
- Use conventional commits where possible
- Reference issue numbers in commits

### Branch Strategy

| Branch | Purpose | Contents |
|--------|---------|----------|
| `main` | Clean showcase / releases | Only module source code |
| `dev` | Active development | Source + dev tooling |

### Dev-Only Files (excluded from main)

These files exist only in the `dev` branch and are excluded from `main`:

| Category | Files | Purpose |
|----------|-------|---------|
| AI Development | `.claude/commands/` | Slash commands for Claude Code |
| AI Development | `CLAUDE.md` | AI assistant instructions |
| Dev Helpers | `Connect-DevNetbox.ps1` | Quick connect script |
| Dev Helpers | `.netboxps.config.example.ps1` | Config template |
| Editor Settings | `.vscode/` | VS Code settings |
| Build Output | `PowerNetbox/` | Built module (gitignored) |

### Merging dev to main

When merging `dev` to `main`, exclude dev-only files:

```bash
# Option 1: Selective merge (recommended)
git checkout main
git merge dev --no-commit
git reset HEAD .claude/ CLAUDE.md Connect-DevNetbox.ps1 .netboxps.config.example.ps1 .vscode/
git checkout -- .claude/ CLAUDE.md Connect-DevNetbox.ps1 .netboxps.config.example.ps1 .vscode/
git commit -m "Merge dev into main (excluding dev files)"

# Option 2: Cherry-pick specific commits
git checkout main
git cherry-pick <commit-hash>

# Option 3: Create release from dev
git checkout dev
git tag v4.4.9
git push origin v4.4.9
```

### .gitignore (main branch)

The `main` branch `.gitignore` includes entries to prevent accidental addition of dev files:

```gitignore
# Development files (keep in dev branch only)
.claude/
CLAUDE.md
Connect-DevNetbox.ps1
.vscode/

# Build output
PowerNetbox/
NetboxPSv4/
```

**Note**: These `.gitignore` entries only prevent NEW files from being added. Files already tracked in `dev` will still come through on merge - use the selective merge approach above.

## Common Issues

### Module not loading after changes
```powershell
# Remove and reimport
Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
Import-Module ./PowerNetbox/PowerNetbox.psd1 -Force
```

### SSL/Certificate errors
```powershell
# Use SkipCertificateCheck parameter
Connect-NBAPI -Hostname "netbox.local" -Credential $cred -SkipCertificateCheck
```

### API returns 403
- Check token permissions in Netbox
- Ensure token hasn't expired
- Verify the API endpoint exists in your Netbox version

## Cross-Platform Compatibility

This module supports Windows, Linux, and macOS with PowerShell 5.1+ and PowerShell Core 7+.

### Platform Support Matrix

| Platform | PowerShell 5.1 | PowerShell 7+ |
|----------|----------------|---------------|
| Windows 10/11 | ✅ Full | ✅ Full |
| Windows Server | ✅ Full | ✅ Full |
| macOS (Intel/ARM) | ❌ N/A | ✅ Full |
| Linux (Ubuntu/Debian/RHEL) | ❌ N/A | ✅ Full |

### Build Script (deploy.ps1)
The build script uses `Join-Path` for all file paths to ensure cross-platform compatibility:
```powershell
# Cross-platform path construction
$FunctionPath = Join-Path $PSScriptRoot 'Functions'
$OutputDirectory = Join-Path $PSScriptRoot $ModuleName
```

### Certificate Handling
SSL/TLS certificate handling differs between PowerShell editions:

| Edition | Method | Notes |
|---------|--------|-------|
| Desktop (5.1) | `ServicePointManager` | Uses `Set-NBCipherSSL` and `Set-NBuntrustedSSL` |
| Core (7+) | `-SkipCertificateCheck` | Native parameter on `Invoke-RestMethod` |

```powershell
# TLS configuration (Set-NBCipherSSL)
# - Desktop: Enables TLS 1.2/1.3 via ServicePointManager
# - Core: Skipped (uses modern TLS by default)

# Certificate validation (Set-NBuntrustedSSL)
# - Desktop: Uses CertificatePolicy callback
# - Core: Uses -SkipCertificateCheck parameter
```

### URL Encoding
Query string building uses `[System.Uri]::EscapeDataString()` instead of `System.Web.HttpUtility` for cross-platform compatibility. This eliminates the need for the Windows-only `System.Web` assembly.

### Line Endings & Encoding
- `.gitattributes` enforces LF line endings for all text files
- Build script uses `utf8NoBOM` encoding on PowerShell Core
- PowerShell Desktop uses `utf8` (with BOM, unavoidable limitation)

### Stream Encoding
All `StreamReader` instances explicitly specify UTF-8 encoding for consistent behavior:
```powershell
$reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
```

### Cross-Platform Checklist for Contributors
When adding new code, ensure:
1. **Paths**: Use `Join-Path` instead of hardcoded separators (`\` or `/`)
2. **Encoding**: Specify UTF-8 encoding explicitly on file/stream operations
3. **TLS/SSL**: Don't assume `ServicePointManager` - check `$PSVersionTable.PSEdition`
4. **Assemblies**: Avoid Windows-only assemblies (e.g., `System.Web`)
5. **Line endings**: Use `\n` (LF) instead of `\r\n` (CRLF) in string literals
