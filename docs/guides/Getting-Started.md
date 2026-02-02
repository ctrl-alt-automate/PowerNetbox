# Getting Started

## Installation

### From PowerShell Gallery (Recommended)

```powershell
# Install for current user
Install-Module -Name PowerNetbox -Scope CurrentUser

# Or install system-wide (requires admin)
Install-Module -Name PowerNetbox -Scope AllUsers
```

### Verify Installation

```powershell
Get-Module PowerNetbox -ListAvailable
```

## Connecting to Netbox

### Basic Connection

```powershell
# Import the module
Import-Module PowerNetbox

# Create credential (API token as password)
$credential = Get-Credential -UserName 'api' -Message 'Enter your Netbox API token'

# Connect
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $credential
```

### Connection with Self-Signed Certificate

```powershell
Connect-NBAPI -Hostname 'netbox.local' -Credential $credential -SkipCertificateCheck
```

### Verify Connection

```powershell
# Get Netbox version
Get-NBVersion

# Should return something like:
# netbox-version : 4.4.8
# python-version : 3.12.3
```

## Basic Commands

### Naming Convention

All functions follow the pattern: `[Verb]-NB[Module][Resource]`

| Verb | Action | HTTP Method |
|------|--------|-------------|
| `Get-` | Retrieve | GET |
| `New-` | Create | POST |
| `Set-` | Update | PATCH |
| `Remove-` | Delete | DELETE |

### Examples

```powershell
# Get all sites
Get-NBDCIMSite

# Get a specific device
Get-NBDCIMDevice -Name 'server01'

# Get devices with filter
Get-NBDCIMDevice -Status 'active' -Site 1

# Create a new IP address
New-NBIPAMAddress -Address '10.0.0.1/24' -Description 'Web Server'

# Update a device
Set-NBDCIMDevice -Id 1 -Description 'Updated via PowerNetbox'

# Delete (with confirmation)
Remove-NBDCIMDevice -Id 1
```

### Getting Help

```powershell
# List all available functions
Get-Command -Module PowerNetbox

# Get help for a specific function
Get-Help Get-NBDCIMDevice -Full

# Show examples
Get-Help New-NBIPAMAddress -Examples
```

## Performance Tips

PowerNetbox implements performance optimizations by default:

```powershell
# Brief mode for minimal response (~90% smaller)
Get-NBDCIMDevice -Brief

# Select specific fields only
Get-NBDCIMDevice -Fields 'id','name','status','site.name'

# config_context is excluded by default for speed
# Include it when needed:
Get-NBDCIMDevice -IncludeConfigContext
```

See [Performance Optimization](Performance-Optimization.md) for detailed guidance.

## Next Steps

- [Performance Optimization](Performance-Optimization.md) - Optimize your API queries
- [Common Workflows](Common-Workflows.md) - Real-world examples
- [DCIM Examples](DCIM-Examples.md) - Device and site management
- [IPAM Examples](IPAM-Examples.md) - IP address management
