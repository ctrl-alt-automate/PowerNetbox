# CLAUDE.md - PowerNetbox Development Guide

## Project Overview

**PowerNetbox** is a PowerShell module for the [Netbox](https://github.com/netbox-community/netbox) REST API. Fork of [NetboxPS](https://github.com/benclaussen/NetboxPS) with full Netbox 4.x compatibility.

| Property | Value |
|----------|-------|
| Module Name | PowerNetbox (PSGallery) |
| Current Version | 4.4.9.0 |
| Target Netbox | 4.4.9 |
| Minimum Netbox | 4.1+ |
| PowerShell | 5.1+ (Desktop and Core) |
| Repository | https://github.com/ctrl-alt-automate/PowerNetbox |
| Functions | 494 public functions |
| Tests | 946 unit + 79 integration |

---

## Git Workflow & Release Process

### Branch Strategy

| Branch | Purpose | Contains |
|--------|---------|----------|
| `dev` | Active development | All code + dev tooling (CLAUDE.md, .claude/, etc.) |
| `main` | Releases & PSGallery | Clean production code only |
| `beta` | Pre-release testing | Netbox 4.5 compatibility work |

### Dev-Only Files (NEVER merge to main)

These files exist ONLY on `dev` and must be excluded when merging:

```
.claude/           # AI agent prompts
CLAUDE.md          # This file
Connect-DevNetbox.ps1
.netboxps.config.example.ps1
.vscode/
```

### Release Workflow (Step-by-Step)

**IMPORTANT**: Releases are ALWAYS made from `main`, NEVER from `dev`.

```bash
# 1. On dev: Make changes, update version in PowerNetbox.psd1
git checkout dev
# ... make changes ...
# Update ModuleVersion in PowerNetbox.psd1

# 2. Commit and push to dev
git add -A
git commit -m "chore: Update to version X.Y.Z.W"
git push origin dev

# 3. Wait for CI tests to pass on dev
gh run list --branch dev --limit 3

# 4. Stash any build output before switching branches
git stash --include-untracked

# 5. Checkout main and pull latest
git checkout main
git pull origin main

# 6. Merge dev into main (EXCLUDING dev-only files)
git merge dev --no-commit --no-ff

# 7. If CLAUDE.md appears in merge, remove it:
git rm --cached CLAUDE.md 2>/dev/null; rm -f CLAUDE.md

# 8. Check that only production files are staged
git status
# Should NOT include: CLAUDE.md, .claude/, Connect-DevNetbox.ps1, .vscode/

# 9. Commit the merge
git commit -m "Merge dev into main for vX.Y.Z.W release"

# 10. Push to main
git push origin main

# 11. Create GitHub release (this triggers PSGallery publish)
gh release create vX.Y.Z.W \
  --target main \
  --title "PowerNetbox vX.Y.Z.W" \
  --notes "Release notes here..."

# 12. Verify release workflow succeeded
gh run list --workflow=release.yml --limit 1

# 13. Return to dev branch
git checkout dev
git stash pop
```

### Common Release Mistakes (AVOID THESE)

| Mistake | Problem | Solution |
|---------|---------|----------|
| Creating release from `dev` | Tag points to wrong commit, PSGallery publish fails | Always merge to `main` first |
| Forgetting to update version | PSGallery rejects duplicate version | Update `PowerNetbox.psd1` before release |
| Including CLAUDE.md in merge | Dev file ends up on main | Use `git rm --cached CLAUDE.md` during merge |
| Not stashing build output | Can't switch branches | `git stash` before `git checkout` |
| Creating release before push | Tag points to old commit | Always `git push` before `gh release create` |

---

## Development Environment

### Quick Start
```powershell
# Build and connect
./deploy.ps1 -Environment dev -SkipVersion
. ./Connect-DevNetbox.ps1
```

### Configuration
```powershell
# First time: copy config template
Copy-Item .netboxps.config.example.ps1 .netboxps.config.ps1
# Edit with your Netbox hostname and API token
```

### Building
```powershell
./deploy.ps1 -Environment dev -SkipVersion   # Development (all functions)
./deploy.ps1 -Environment prod -SkipVersion  # Production (public only)
```

### Testing
```powershell
Invoke-Pester ./Tests/                        # All unit tests
Invoke-Pester ./Tests/ -Tag 'Integration'     # Integration tests
```

### Docker Integration Testing
```bash
docker compose -f docker-compose.ci.yml up -d
# Wait 2-3 minutes, then:
$env:NETBOX_HOST = 'localhost:8000'
$env:NETBOX_TOKEN = '0123456789abcdef0123456789abcdef01234567'
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Live'
docker compose -f docker-compose.ci.yml down -v
```

---

## Project Structure (Key Files)

```
PowerNetbox/
├── Functions/           # Source: one function per .ps1 file
│   ├── DCIM/            # 45 endpoints, 180 functions
│   ├── IPAM/            # 18 endpoints, 72 functions
│   ├── Virtualization/  # 5 endpoints, 20 functions
│   ├── Circuits/        # 11 endpoints, 44 functions
│   ├── Tenancy/         # 5 endpoints, 20 functions
│   ├── VPN/             # 10 endpoints, 40 functions
│   ├── Wireless/        # 3 endpoints, 12 functions
│   ├── Extras/          # 12 endpoints, 45 functions
│   ├── Core/            # 5 endpoints, 8 functions
│   ├── Users/           # 4 endpoints, 16 functions
│   ├── Plugins/Branching/  # 16 functions (plugin)
│   ├── Helpers/         # Internal helpers
│   └── Setup/           # Connection functions
├── Tests/               # Pester tests
├── PowerNetbox.psd1     # Module manifest (SOURCE)
├── PowerNetbox.psm1     # Module loader (SOURCE)
├── deploy.ps1           # Build script
├── .claude/commands/    # AI agent prompts (dev-only)
└── CLAUDE.md            # This file (dev-only)
```

**Build Output** (gitignored): `PowerNetbox/PowerNetbox.psd1` and `PowerNetbox.psm1`

---

## Function Naming & Templates

### Naming Pattern
`[Verb]-NB[Module][Resource]`

| Verb | HTTP | Example |
|------|------|---------|
| Get- | GET | `Get-NBDCIMDevice` |
| New- | POST | `New-NBIPAMAddress` |
| Set- | PATCH | `Set-NBVirtualMachine` |
| Remove- | DELETE | `Remove-NBDCIMSite` |

### GET Template
```powershell
function Get-NB[Module][Resource] {
    [CmdletBinding()]
    param (
        [uint16]$Limit,
        [uint16]$Offset,
        [Parameter(ValueFromPipelineByPropertyName)]
        [uint64[]]$Id,
        [string]$Name,
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

### NEW Template
```powershell
function New-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('[module]', '[resource]'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Name, 'Create [Resource]')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
```

### SET Template
```powershell
function Set-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [uint64]$Id,
        [string]$Name,
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

### REMOVE Template
```powershell
function Remove-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
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

---

## Bulk Operations

Pipeline-based bulk operations for high-performance batch processing:

```powershell
# Bulk create via pipeline
1..100 | ForEach-Object {
    [PSCustomObject]@{ Name = "server-$_"; Role = 1; Device_Type = 1; Site = 1 }
} | New-NBDCIMDevice -BatchSize 50 -Force

# Bulk update
Get-NBDCIMDevice -Status "planned" | ForEach-Object {
    [PSCustomObject]@{ Id = $_.id; Status = "active" }
} | Set-NBDCIMDevice -Force

# Bulk delete
Get-NBDCIMDevice -Status "decommissioning" | Remove-NBDCIMDevice -Force
```

**Parameters**: `-InputObject` (pipeline), `-BatchSize` (default 50), `-Force` (skip confirm)

**Supported**: New-NBDCIMDevice, New-NBDCIMInterface, New-NBIPAMAddress, New-NBIPAMPrefix, New-NBIPAMVLAN, New-NBVirtualMachine, New-NBVirtualMachineInterface, Set-NBDCIMDevice, Remove-NBDCIMDevice

---

## Slash Commands

AI agent prompts in `.claude/commands/`:

| Command | Purpose |
|---------|---------|
| `/netbox-api [endpoint]` | Research API endpoint schema |
| `/powershell-expert [question]` | PowerShell best practices |
| `/implement [endpoint]` | Full implementation workflow |
| `/test-endpoint [function]` | Test against live Netbox |

---

## Key Helper Functions

| Function | Purpose |
|----------|---------|
| `BuildNewURI` | Construct API URI from segments |
| `BuildURIComponents` | Process PSBoundParameters into URI/body |
| `InvokeNetboxRequest` | Execute REST API call with auth |
| `Send-NBBulkRequest` | Batch API calls for bulk operations |

---

## Code Style

- One function per file
- `[CmdletBinding()]` on all functions
- `SupportsShouldProcess` for state-changing operations
- `process {}` blocks for pipeline support
- `-Raw` switch on all functions
- `Write-Verbose` for debug (never `Write-Host`)

### Export Policy
- **Production**: Only functions with `-` in name (public API)
- **Development**: All functions including helpers

---

## Wiki

Location: `/Users/elvis/Developer/work/PowerNetbox.wiki/`

```bash
# Push wiki changes (uses master branch)
cd /Users/elvis/Developer/work/PowerNetbox.wiki
git add . && git commit -m "Update" && git push origin main:master
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Module not loading | `Remove-Module PowerNetbox -Force; Import-Module ./PowerNetbox/PowerNetbox.psd1 -Force` |
| SSL errors | `Connect-NBAPI -SkipCertificateCheck` |
| 403 errors | Check token permissions, verify endpoint exists |
| Can't switch branch | `git stash` build output first |

---

## Cross-Platform Notes

- Use `Join-Path` for paths (not `\` or `/`)
- Use `[System.Uri]::EscapeDataString()` for URL encoding
- Check `$PSVersionTable.PSEdition` for PS version-specific code
- Desktop uses `ServicePointManager`, Core uses `-SkipCertificateCheck`
