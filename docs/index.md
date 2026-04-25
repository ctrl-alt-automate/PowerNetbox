---
title: Home
hide:
  - toc
render_macros: true
---

# PowerNetbox

[![PSGallery version](https://img.shields.io/powershellgallery/v/PowerNetbox?label=PSGallery&color=2980b9)](https://www.powershellgallery.com/packages/PowerNetbox)
[![Downloads](https://img.shields.io/powershellgallery/dt/PowerNetbox?label=downloads&color=4caf50)](https://www.powershellgallery.com/packages/PowerNetbox)
[![GitHub stars](https://img.shields.io/github/stars/ctrl-alt-automate/PowerNetbox?style=social)](https://github.com/ctrl-alt-automate/PowerNetbox)

The comprehensive PowerShell module for the [NetBox](https://github.com/netbox-community/netbox)
REST API - {{ cmdlet_count() }} cmdlets covering DCIM, IPAM, Virtualization, Circuits,
Tenancy, VPN, Wireless, and the netbox-branching plugin.

## Why PowerNetbox

- **100% API coverage** — every NetBox endpoint, every CRUD verb, including the netbox-branching plugin
- **Cross-platform** — PowerShell 5.1 on Windows, PowerShell 7+ on Linux, macOS, and Windows
- **Built for scale** — `-Brief`, `-Fields`, `-Omit` switches and pipeline-based bulk operations keep responses fast on NetBox instances with thousands of objects

## Quickstart

```powershell
# Install
Install-Module -Name PowerNetbox -Scope CurrentUser

# Connect (paste your NetBox API token when prompted)
$cred = Get-Credential -UserName 'api'
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $cred

# Query
Get-NBDCIMDevice -Brief
```

<div class="pn-cta-row" markdown>
[:material-rocket-launch: Getting Started](getting-started/connecting.md){ .md-button .md-button--primary }
[:material-book-open-variant: Browse Reference](reference/index.md){ .md-button }
</div>

## Latest release

{{ latest_release() }}

## Compatibility

{{ compat_table() }}

[Compatibility testing details](guides/compatibility.md)
