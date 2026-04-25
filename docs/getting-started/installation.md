---
title: Installation
---

# Installation

PowerNetbox is available on the [PowerShell Gallery](https://www.powershellgallery.com/packages/PowerNetbox)
and supports PowerShell 5.1 (Windows) and PowerShell 7+ (Windows, Linux, macOS).

## From PowerShell Gallery (recommended)

Install for your current user - no administrator rights required:

```powershell
Install-Module -Name PowerNetbox -Scope CurrentUser
```

Or install system-wide (requires administrator/sudo):

```powershell
Install-Module -Name PowerNetbox -Scope AllUsers
```

Once installed, import the module:

```powershell
Import-Module PowerNetbox
```

## From source

Clone the repository and build the module from source. The `deploy.ps1` script
concatenates all function files under `Functions/` into the single loadable
`.psm1` — this build step is required once before you can import the module.

```powershell
git clone https://github.com/ctrl-alt-automate/PowerNetbox.git
cd PowerNetbox

# Build the module (concatenation step - required)
./deploy.ps1 -Environment dev -SkipVersion

# Import the built module
Import-Module ./PowerNetbox/PowerNetbox.psd1 -Force
```

## Verify installation

Check that the module loaded and see the version:

```powershell
Get-Module PowerNetbox -ListAvailable
```

Expected output shows module name, version, and path. To confirm the cmdlets
are available (~500 exported commands):

```powershell
(Get-Command -Module PowerNetbox).Count
```

## Next

[Connect to NetBox](connecting.md)
