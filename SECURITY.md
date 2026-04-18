# Security Policy

## Supported versions

Only the latest released version of PowerNetbox receives security updates.
Older versions are not patched retroactively. Upgrade via:

```powershell
Update-Module -Name PowerNetbox
```

## Reporting a vulnerability

**Please do not report security issues via public GitHub issues.**

Preferred channel: [GitHub Security Advisories](https://github.com/ctrl-alt-automate/PowerNetbox/security/advisories/new)
— this creates a private advisory thread between you and the maintainer.

Fallback: email `31536997+ctrl-alt-automate@users.noreply.github.com` with
subject line starting `[SECURITY]`.

## What to include

- PowerNetbox version (`Get-Module PowerNetbox | Select-Object Version`)
- NetBox server version (if relevant)
- PowerShell edition + version (`$PSVersionTable`)
- Clear reproduction steps and the observed impact
- Whether you need credit in the advisory

## What to expect

- Acknowledgement within 5 business days
- Triage and initial severity assessment within 10 business days
- Fix timeline scaled to severity (CRITICAL issues aim for 7 days; LOW may
  be bundled with a regular release)
- Credit in the advisory + release notes unless you request otherwise

## Scope

**In scope:**

- PowerNetbox cmdlet code (`Functions/**`)
- Authentication and token handling (`Functions/Setup/**`, `Functions/Helpers/InvokeNetboxRequest.ps1`)
- Request construction and response parsing
- Build and release pipeline (`.github/workflows/`)
- Dependencies declared by this module

**Out of scope:**

- Vulnerabilities in NetBox itself — report to
  [netbox-community/netbox](https://github.com/netbox-community/netbox/security)
- Vulnerabilities in PowerShell or .NET — report upstream
- Social engineering, physical access, or denial-of-service via sheer
  volume (PowerNetbox inherits NetBox's rate limiting)
- Issues that require an already-compromised host / session

## Security posture

PowerNetbox publishes security review documents in
[`docs/superpowers/reviews/`](docs/superpowers/reviews/). Recent reviews:

- **2026-04-18 Tier 1** — secret scanning, GitHub Actions workflow hardening, cryptographic delta audit since PR #377
- **2026-04-18 Tier 2** — STRIDE threat model, OWASP API Top 10 (client-side), dependency / supply-chain audit

Current hardening includes:

- HTTPS by default with plaintext-HTTP warning
- Central `Authorization: Bearer` header construction with v1/v2 token support
- Token redaction in verbose / error output
- Cross-origin validation on pagination `.next` URLs (PR #404)
- `gitleaks` CI + `.gitleaks-baseline.json` + pre-commit hook (PR #403)
- Restricted GitHub Actions permissions (`contents: read` default)
- Client-side 10 MB upload cap on `New-NBImageAttachment` (see `Functions/Extras/ImageAttachments/New-NBImageAttachment.ps1`); client-side default 10 000-item cap on `Send-NBBulkRequest` via `-MaxItems` (see `Functions/Helpers/Send-NBBulkRequest.ps1`). Both are local guards that throw before any network call — server-side limits from NetBox apply on top.

## Code signing

The published module on PSGallery is **not yet code-signed**. An
application with [SignPath Foundation](https://signpath.org) for free
open-source code signing is in progress. Until then, consumers can
verify authenticity via:

1. **PSGallery publisher:** modules are published only by the
   `ctrl-alt-automate` publisher account.
2. **Git tag SHA:** each release tag matches a commit on `main`; you
   can verify by inspecting `git log` on your local clone.
3. **Review the source:** PowerNetbox is MIT-licensed; the full source
   of every released version is public at the matching tag.

Once SignPath signing is live this section will be updated with
`Get-AuthenticodeSignature` verification steps.
