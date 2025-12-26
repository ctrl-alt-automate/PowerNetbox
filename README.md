# PowerNetbox

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PowerNetbox?label=PSGallery&logo=powershell&logoColor=white)](https://www.powershellgallery.com/packages/PowerNetbox)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/PowerNetbox?label=Downloads&logo=powershell&logoColor=white)](https://www.powershellgallery.com/packages/PowerNetbox)
[![Tests](https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/test.yml/badge.svg)](https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/test.yml)
[![Lint](https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/pssa.yml/badge.svg)](https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/pssa.yml)
[![License](https://img.shields.io/github/license/ctrl-alt-automate/PowerNetbox)](LICENSE)
[![Netbox Version](https://img.shields.io/badge/Netbox-4.4.9-blue?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyTDIgN2wxMCA1IDEwLTV6TTIgMTdsMTAgNSAxMC01TTIgMTJsMTAgNSAxMC01Ii8+PC9zdmc+)](https://github.com/netbox-community/netbox)
[![Integration Tests](https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/integration.yml/badge.svg)](https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/integration.yml)

**The** comprehensive PowerShell module for the [Netbox](https://github.com/netbox-community/netbox) REST API with **100% coverage**. Fully compatible with **Netbox 4.4.9**.

---

## Acknowledgements

This project is a fork of the original **[NetboxPS](https://github.com/benclaussen/NetboxPS)** created by **[Ben Claussen](https://github.com/benclaussen)**.

We extend our sincere thanks to Ben and all original contributors for building the foundation of this module. Their work made PowerNetbox possible.

| | |
|---|---|
| **Original Author** | [Ben Claussen](https://github.com/benclaussen) |
| **Original Repository** | [benclaussen/NetboxPS](https://github.com/benclaussen/NetboxPS) |
| **License** | MIT (preserved from original) |

---

## Features

- **100% API Coverage** - Full support for all Netbox 4.x API endpoints
- **Cross-Platform** - Works on Windows, Linux, and macOS
- **504+ Functions** - Complete CRUD operations for all resources
- **Pipeline Support** - Full PowerShell pipeline integration
- **Secure** - Token-based authentication with TLS 1.2/1.3
- **Well Tested** - 946 unit tests for quality assurance

### Supported Modules

| Module | Endpoints | Functions | Status |
|--------|-----------|-----------|--------|
| DCIM | 45 | 180 | ✅ Full |
| IPAM | 18 | 72 | ✅ Full |
| Virtualization | 5 | 20 | ✅ Full |
| Circuits | 11 | 44 | ✅ Full |
| Tenancy | 5 | 20 | ✅ Full |
| VPN | 10 | 40 | ✅ Full |
| Wireless | 3 | 12 | ✅ Full |
| Extras | 12 | 45 | ✅ Full |
| Core | 5 | 8 | ✅ Full |
| Users | 4 | 16 | ✅ Full |
| Branching* | 3 | 16 | ✅ Full |

\* Requires [netbox-branching](https://github.com/netboxlabs/netbox-branching) plugin

## Installation

### From PowerShell Gallery (Recommended)

```powershell
# Install for current user
Install-Module -Name PowerNetbox -Scope CurrentUser

# Install system-wide (requires admin/root)
Install-Module -Name PowerNetbox -Scope AllUsers
```

### Platform-Specific Instructions

#### Windows

```powershell
# PowerShell 5.1 (Windows PowerShell)
Install-Module -Name PowerNetbox -Scope CurrentUser

# PowerShell 7+ (recommended)
pwsh -Command "Install-Module -Name PowerNetbox -Scope CurrentUser"
```

#### macOS

```bash
# Install PowerShell 7 via Homebrew
brew install powershell/tap/powershell

# Install PowerNetbox
pwsh -Command "Install-Module -Name PowerNetbox -Scope CurrentUser"
```

#### Linux (Ubuntu/Debian)

```bash
# Install PowerShell 7
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# Install PowerNetbox
pwsh -Command "Install-Module -Name PowerNetbox -Scope CurrentUser"
```

### Manual Installation

```powershell
# Clone the repository
git clone https://github.com/ctrl-alt-automate/PowerNetbox.git
cd PowerNetbox

# Build the module
./deploy.ps1 -Environment prod -SkipVersion

# Import the module
Import-Module ./PowerNetbox/PowerNetbox.psd1
```

## Quick Start

### Connect to Netbox

```powershell
# Import the module
Import-Module PowerNetbox

# Connect with API token
$credential = Get-Credential -UserName 'api' -Message 'Enter your Netbox API token'
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $credential

# Or connect with self-signed certificate
Connect-NBAPI -Hostname 'netbox.local' -Credential $credential -SkipCertificateCheck
```

### Basic Examples

```powershell
# Get all devices
Get-NBDCIMDevice

# Get a specific device by name
Get-NBDCIMDevice -Name 'server01'

# Create a new IP address
New-NBIPAMAddress -Address '10.0.0.1/24' -Description 'Web Server'

# Update a device
Set-NBDCIMDevice -Id 1 -Description 'Updated description'

# Delete a device (with confirmation)
Remove-NBDCIMDevice -Id 1

# Pipeline support
Get-NBDCIMDevice -Name 'server*' | Set-NBDCIMDevice -Status 'active'
```

### Advanced Examples

```powershell
# Create a VM with interface and IP
$vm = New-NBVirtualMachine -Name 'web-server-01' -Cluster 1 -Status 'active'
$interface = New-NBVirtualMachineInterface -Name 'eth0' -Virtual_Machine $vm.id
$ip = New-NBIPAMAddress -Address '192.168.1.100/24'
Set-NBIPAMAddress -Id $ip.id -Assigned_Object_Type 'virtualization.vminterface' -Assigned_Object_Id $interface.id

# Bulk operations with pipeline
Import-Csv devices.csv | ForEach-Object {
    New-NBDCIMDevice -Name $_.Name -Device_Type $_.Type -Site $_.Site
}

# Query with filters
Get-NBIPAMAddress -Status 'active' -Tenant 1 -Limit 100
```

### Branching Support (Plugin Required)

PowerNetbox supports the [netbox-branching](https://github.com/netboxlabs/netbox-branching) plugin for staging changes:

```powershell
# Check if branching is available
Test-NBBranchingAvailable

# Create a new branch
New-NBBranch -Name "feature/new-datacenter" -Description "Planning new DC"

# Enter branch context - all subsequent operations work in this branch
Enter-NBBranch -Name "feature/new-datacenter"
    New-NBDCIMSite -Name "DC-New" -Slug "dc-new"
    New-NBDCIMDevice -Name "server01" -DeviceType 1 -Site 1
Exit-NBBranch

# Or use Invoke-NBInBranch for exception-safe execution
Invoke-NBInBranch -Branch "staging" -ScriptBlock {
    Set-NBDCIMDevice -Id 1 -Status "planned"
    New-NBIPAMAddress -Address "10.0.0.1/24"
}

# Review changes in a branch
Get-NBChangeDiff -Branch_Id 1

# Sync branch with latest main
Sync-NBBranch -Id 1

# Merge changes to main
Merge-NBBranch -Id 1

# Revert a merge if needed
Undo-NBBranchMerge -Id 1
```

## Migrating from NetboxPS / NetboxPSv4

If you're migrating from the original NetboxPS or NetboxPSv4 module:

```powershell
# Remove old module
Remove-Module NetboxPS, NetboxPSv4 -Force -ErrorAction SilentlyContinue
Uninstall-Module NetboxPS, NetboxPSv4 -Force -ErrorAction SilentlyContinue

# Install PowerNetbox
Install-Module -Name PowerNetbox -Scope CurrentUser

# Import new module
Import-Module PowerNetbox
```

**All function names remain the same** (`Get-NBDCIMDevice`, `New-NBIPAMAddress`, etc.), so your existing scripts should work without modification.

## Documentation

- **[Wiki](https://github.com/ctrl-alt-automate/PowerNetbox/wiki)** - Getting started, examples, and troubleshooting
- **[Netbox API Docs](https://netbox.readthedocs.io/en/stable/rest-api/overview/)** - Official Netbox API documentation
- **[GitHub Issues](https://github.com/ctrl-alt-automate/PowerNetbox/issues)** - Report bugs or request features

### Wiki Highlights

| Page | Description |
|------|-------------|
| [Getting Started](https://github.com/ctrl-alt-automate/PowerNetbox/wiki/Getting-Started) | Installation and first steps |
| [Common Workflows](https://github.com/ctrl-alt-automate/PowerNetbox/wiki/Common-Workflows) | Bulk import, VMware sync, reporting |
| [DCIM Examples](https://github.com/ctrl-alt-automate/PowerNetbox/wiki/DCIM-Examples) | Sites, devices, racks, cables |
| [IPAM Examples](https://github.com/ctrl-alt-automate/PowerNetbox/wiki/IPAM-Examples) | IP addresses, prefixes, VLANs |
| [Branching](https://github.com/ctrl-alt-automate/PowerNetbox/wiki/Branching) | Stage changes with branching plugin |
| [Compatibility](https://github.com/ctrl-alt-automate/PowerNetbox/wiki/Compatibility) | Netbox version support matrix |
| [Troubleshooting](https://github.com/ctrl-alt-automate/PowerNetbox/wiki/Troubleshooting) | Common issues and solutions |

## Requirements

| Platform | Minimum Version |
|----------|----------------|
| PowerShell Desktop | 5.1 |
| PowerShell Core | 7.0+ |
| Netbox | 4.1+ (tested with 4.4.9) |

> **Version Compatibility:** See the [Compatibility Guide](https://github.com/ctrl-alt-automate/PowerNetbox/wiki/Compatibility) for detailed information about supported Netbox versions and API differences.

### Platform Support

| OS | PowerShell 5.1 | PowerShell 7+ |
|----|----------------|---------------|
| Windows 10/11 | ✅ | ✅ |
| Windows Server | ✅ | ✅ |
| macOS | N/A | ✅ |
| Linux | N/A | ✅ |

## Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch from `dev`
3. Follow [PowerShell Practice and Style Guidelines](https://poshcode.gitbook.io/powershell-practice-and-style/)
4. Submit a pull request against the `dev` branch

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Original copyright (c) 2018 Ben Claussen. Fork maintained by ctrl-alt-automate.

## Changelog

### v4.4.9.0

- **Full Netbox 4.4.9 compatibility** - Tested with latest stable release
- **Docker-based integration testing** - 79 live API tests against real Netbox
- **946 unit tests** across all platforms
- **494 public functions** with 100% API coverage

### v4.4.8.2

- Docker-based CI/CD integration testing
- Documentation updates

### v4.4.8.1

- New versioning: `Major.Minor.Patch.ModulePatch` (first 3 digits = Netbox version)
- PowerShell 5.1 compatibility fix for `Remove-NBDCIMSite`
- SecureString support for password parameters in User functions
- Code quality improvements (OutputType, ValidateNotNullOrEmpty)

### v4.4.8

- **Initial PowerNetbox release** (fork of NetboxPS)
- **100% API coverage** for Netbox 4.4.8
- **478 public functions** across all modules
- **613 unit tests** for quality assurance
- **Cross-platform support** - Windows, Linux, macOS
- New modules: VPN, Wireless, Core, Users
- All function names unchanged for backwards compatibility
