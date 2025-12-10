# CLAUDE.md - NetboxPS Development Guide

This file provides guidance to Claude Code (or any AI assistant) when working with this codebase.

## Project Overview

**NetboxPS** is a PowerShell module that provides a wrapper for the [Netbox](https://github.com/netbox-community/netbox) REST API. It allows users to interact with Netbox infrastructure management directly from PowerShell.

- **Current Version**: 1.8.5
- **Target Netbox Version**: 4.4.7 (working towards full compatibility)
- **Minimum Netbox Version**: 2.8.x
- **PowerShell Version**: 5.0+
- **Repository**: Fork of https://github.com/benclaussen/NetboxPS
- **Issue Tracking**: https://github.com/ctrl-alt-automate/NetboxPS/issues

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
Connect-NetboxAPI -Hostname $config.Hostname -Credential $cred
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
4. Outputs to `NetboxPS/` directory

### Running Tests
```powershell
# Run all Pester tests
Invoke-Pester ./Tests/

# Run specific test file
Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1
```

## Project Structure

```
NetboxPS/
├── Functions/                    # Source files - one function per file (130 functions)
│   ├── Circuits/                 # Circuit management
│   │   ├── Circuits/
│   │   ├── Providers/
│   │   ├── Terminations/
│   │   └── Types/
│   ├── DCIM/                     # Data Center Infrastructure
│   │   ├── Cable Terminations/
│   │   ├── Cables/
│   │   ├── Devices/
│   │   ├── FrontPorts/
│   │   ├── Interfaces/
│   │   ├── Locations/            # Get/New/Set/Remove
│   │   ├── Manufacturers/        # Get/New/Set/Remove
│   │   ├── Racks/                # Get/New/Set/Remove
│   │   ├── RearPorts/
│   │   ├── Regions/              # Get/New/Set/Remove
│   │   ├── SiteGroups/           # Get/New/Set/Remove
│   │   └── Sites/
│   ├── Extras/                   # Tags, custom fields, etc.
│   ├── Helpers/                  # Internal helper functions
│   ├── IPAM/                     # IP Address Management
│   │   ├── Address/
│   │   ├── Aggregate/
│   │   ├── Prefix/
│   │   ├── Range/
│   │   ├── Role/
│   │   ├── RouteTarget/          # Get/New/Set/Remove
│   │   ├── VLAN/
│   │   └── VRF/                  # Get/New/Set/Remove
│   ├── Setup/                    # Connection and configuration
│   │   └── Support/
│   ├── Tenancy/                  # Tenants, contacts
│   └── Virtualization/           # VMs, clusters
├── Tests/                        # Pester tests
├── .claude/commands/             # Specialized AI agent prompts
├── NetboxPS/                     # Build output directory
├── NetboxPS.psd1                 # Module manifest (source)
├── NetboxPS.psm1                 # Root module file (source)
├── Connect-DevNetbox.ps1         # Quick connect helper script
└── deploy.ps1                    # Build script
```

## Function Naming Convention

Functions follow this pattern: `[Verb]-Netbox[Module][Resource]`

| Verb | Purpose | HTTP Method |
|------|---------|-------------|
| `Get-` | Retrieve resources | GET |
| `New-` | Create resources | POST |
| `Set-` | Update resources | PATCH |
| `Remove-` | Delete resources | DELETE |
| `Add-` | Create child resources (legacy, prefer `New-`) | POST |

Examples:
- `Get-NetboxDCIMDevice` - Get devices from DCIM module
- `New-NetboxIPAMAddress` - Create new IP address
- `Set-NetboxVirtualMachine` - Update a virtual machine
- `Remove-NetboxDCIMSite` - Delete a site

## Creating New Functions

### Template for GET Function
```powershell
function Get-Netbox[Module][Resource] {
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
function New-Netbox[Module][Resource] {
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
function Set-Netbox[Module][Resource] {
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
function Remove-Netbox[Module][Resource] {
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
| Setup | `/api/status/` | Implemented |
| DCIM | `/api/dcim/` | Partial |
| IPAM | `/api/ipam/` | Partial |
| Virtualization | `/api/virtualization/` | Partial |
| Tenancy | `/api/tenancy/` | Partial |
| Circuits | `/api/circuits/` | Partial |
| Extras | `/api/extras/` | Minimal |
| VPN | `/api/vpn/` | **Not implemented** |
| Wireless | `/api/wireless/` | **Not implemented** |
| Core | `/api/core/` | **Not implemented** |
| Users | `/api/users/` | **Not implemented** |

## Netbox 4.x Compatibility

### Known Breaking Changes (Fixed)
| Issue | Old Behavior | New Behavior (4.x) | Status |
|-------|--------------|-------------------|--------|
| ContentTypes endpoint | `/api/extras/content-types/` | `/api/core/object-types/` | ✅ Fixed |
| VM Site parameter | Mandatory | Optional (only Name required) | ✅ Fixed |
| Set-NetboxDCIMSite | Missing | Added | ✅ Fixed |

### API Endpoints Changed in Netbox 4.x
- `/api/extras/content-types/` → `/api/core/object-types/`
- Several fields that were mandatory are now optional
- New modules added: VPN, Wireless

### Testing Against Netbox 4.4.7
All GET functions (31) have been tested and work correctly.
CRUD operations tested for: Sites, IP Addresses, Virtual Machines, Racks, Manufacturers, Locations, Regions, SiteGroups, VRFs, RouteTargets.

## Roadmap & Issues

See [GitHub Issues](https://github.com/ctrl-alt-automate/NetboxPS/issues) for the full roadmap:
- **v2.0.0**: Netbox 4.x compatibility testing and fixes *(in progress)*
- **v2.1.0**: DCIM expansion (racks ✅, locations ✅, regions ✅, site-groups ✅, manufacturers ✅)
- **v2.2.0**: IPAM expansion (VRFs ✅, route targets ✅, ASNs, services)
- **v2.3.0**: New modules (VPN, Wireless)

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
- Support `-WhatIf`/`-Confirm` for state-changing operations
- Use proper parameter validation attributes
- Include pipeline support where appropriate (`ValueFromPipelineByPropertyName`)
- Always include `-Raw` switch to return unprocessed API response
- Use `Write-Verbose` for debug output, never `Write-Host`

## Slash Commands (Specialized Agents)

This project includes specialized slash commands in `.claude/commands/` for different expertise areas:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/netbox-api [endpoint]` | Netbox API expert | Research endpoint schemas, understand API structure |
| `/powershell-expert [question]` | PowerShell best practices | Code review, pattern questions, modern PS guidance |
| `/implement [endpoint]` | Combined implementation workflow | Creating new endpoint functions (uses both experts) |
| `/test-endpoint [function]` | Compatibility testing | Verify functions work against Netbox 4.4.7 |

### Usage Examples
```bash
# Research an API endpoint before implementing
/netbox-api dcim/racks

# Ask about PowerShell patterns
/powershell-expert how should I handle pagination in Get functions?

# Implement a complete new endpoint (recommended workflow)
/implement dcim/locations

# Test an existing function for compatibility
/test-endpoint Get-NetboxDCIMDevice
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

## Common Issues

### Module not loading after changes
```powershell
# Remove and reimport
Remove-Module NetboxPS -Force -ErrorAction SilentlyContinue
Import-Module ./NetboxPS/NetboxPS.psd1 -Force
```

### SSL/Certificate errors
```powershell
# Use SkipCertificateCheck parameter
Connect-NetboxAPI -Hostname "netbox.local" -Credential $cred -SkipCertificateCheck
```

### API returns 403
- Check token permissions in Netbox
- Ensure token hasn't expired
- Verify the API endpoint exists in your Netbox version
