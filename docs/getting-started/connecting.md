---
title: Connecting to NetBox
---

# Connecting to NetBox

This page covers establishing a connection to NetBox. For installation,
see [Installation](installation.md). For deeper authentication topics including
v2 tokens and token rotation, see [Authentication](authentication.md).

## Basic connection

```powershell
# Import the module
Import-Module PowerNetbox

# Create a credential - use 'api' as the username (NetBox convention)
# and paste your API token as the password
$cred = Get-Credential -UserName 'api' -Message 'Enter your NetBox API token'

# Connect
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $cred
```

The username is the literal string `'api'`. NetBox ignores it; only the token
in the password field matters.

## Connection with self-signed certificate

For internal NetBox instances with self-signed TLS certificates:

```powershell
Connect-NBAPI -Hostname 'netbox.local' -Credential $cred -SkipCertificateCheck
```

!!! warning
    `-SkipCertificateCheck` disables certificate validation for the entire
    PowerShell session. Use only for trusted internal instances.

## Verify connection

```powershell
Get-NBVersion
# Returns: netbox-version, python-version, etc.
```

## Performance

See [Performance Optimization](../guides/performance.md) for tips on reducing
response size and speeding up large queries.

## Next steps

- [Your first device](your-first-device.md) - 5-minute end-to-end tutorial
- [Authentication](authentication.md) - v2 tokens, certs, service accounts
- [Common workflows](../guides/common-workflows.md) - Real-world examples
- [Performance Optimization](../guides/performance.md) - Faster queries
