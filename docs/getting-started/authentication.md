---
title: Authentication
---

# Authentication

PowerNetbox authenticates against the NetBox REST API using a token. NetBox 4.5+
introduced a new v2 token format with explicit key and token segments. v1 tokens
still work in 4.5 and 4.6 but are deprecated and will be removed in NetBox 4.7.

## v1 vs v2 token format

| | v1 (legacy) | v2 (NetBox 4.5+) |
|---|---|---|
| Format | 40-char hex string | `nbt_<keyid>.<token>` |
| Header sent | `Authorization: Token <token>` | `Authorization: Bearer <token>` |
| Status | Deprecated; removed in 4.7 | Recommended |

PowerNetbox auto-detects the token format and sends the correct header. You do
not need to configure anything extra. Just paste the token NetBox gave you into
the credential prompt.

## Connecting with a credential

The standard pattern uses `Get-Credential` to keep the token out of shell history:

```powershell
$cred = Get-Credential -UserName 'api' -Message 'Paste your NetBox API token'
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $cred
```

The username is the literal string `'api'` (NetBox convention; the username is
ignored, only the token in the password field matters).

For non-interactive scripts (CI, automation), build the credential from an
environment variable:

```powershell
$secure = ConvertTo-SecureString $env:NETBOX_TOKEN -AsPlainText -Force
$cred   = New-Object PSCredential('api', $secure)
Connect-NBAPI -Hostname $env:NETBOX_HOST -Credential $cred
```

## Self-signed certificates

For internal NetBox instances with self-signed TLS certificates, add
`-SkipCertificateCheck`:

```powershell
Connect-NBAPI -Hostname 'netbox.local' -Credential $cred -SkipCertificateCheck
```

!!! warning
    `-SkipCertificateCheck` disables certificate validation for the entire
    PowerShell session, not just one cmdlet. Use only for trusted internal
    instances. On PowerShell 7.4+ this also enables `AllowInsecureRedirect`.

## Service-account tokens and rotation

For automated workflows, create a dedicated NetBox user (for example,
`svc-powernetbox`) with the minimum permissions needed and generate a token for it.

Best practices:

- **Rotate quarterly** at minimum, and immediately if a token is exposed.
- **Scope per environment** - separate tokens for dev, staging, and prod.
- **Set a short expiry** in NetBox when creating the token, so a forgotten
  token cannot outlive its purpose.
- **Store outside the repo** - environment variables, CI secrets, or a
  secrets vault. PowerNetbox does not log the token, but anything you paste
  into a REPL is in your shell history.
