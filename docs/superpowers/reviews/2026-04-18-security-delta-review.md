---
title: Security Delta Review — 2026-04-18
scope: PR #377 (2026-03-17) → HEAD (7b42e36, 2026-04-17)
reviewer: Claude Opus 4.7 (1M) + Elvis
status: findings-documented
---

# Security Delta Review — 2026-04-18

## Scope

Review of security posture changes between PR #377 ("Security hardening across
module, CI/CD, and Docker") and the current `dev` HEAD (`7b42e36`). Three
cybersecurity-skills toolkits were used:

1. `implementing-secret-scanning-with-gitleaks`
2. `securing-github-actions-workflows`
3. `performing-cryptographic-audit-of-application`

## TL;DR

- **No new critical or high findings since PR #377.** The hardening work from
  that PR has been preserved through subsequent releases.
- **One historic critical** surfaced: 4 real test-instance API tokens leaked
  to public git history between 2025-12-10 and 2026-01-06. **All four are now
  dead** (rejected with `Invalid token`), so the exposure is stale but worth
  documenting. Gitleaks baseline + CI workflow added to prevent recurrence.
- **Positive finding:** zwqg2756 token is protected by NetBox's per-token IP
  allowlist — a defense-in-depth layer that limited the blast radius.
- 2 medium and 3 low informational items captured for future hardening.

## Findings

### 1. [CRITICAL, HISTORIC, RESOLVED] Public git history contains 4 dead test-instance tokens

**Source:** gitleaks 8.30.1 full-history scan (724 commits).

**Exposed tokens:**

| Host | Token prefix | Format | First commit | Last commit | Live? |
|---|---|---|---|---|---|
| `zwqg2756.cloud.netboxapp.com` | `a9717b9520d5…` | v1 (40-hex) | `ef1726d4` 2025-12-10 | `02c3b95` 2026-01-03 | No — `Invalid v1 token` |
| `plasma-paint.exe.xyz` | `4188039a3a05…` | v1 (40-hex) | `02c3b95` 2026-01-03 | — | No — `Invalid token` |
| `zulu-how.exe.xyz` | `nbt_kVJSfSxl3xvO.b4KIab…` | v2 Bearer | `02c3b95` 2026-01-03 | `8044791c` 2026-01-06 | No — `Invalid v2 token` |
| `badger-victor.exe.xyz` | `aaaa4bb91eb7…` | v1 (40-hex) | `02c3b95` 2026-01-03 | — | No — `Invalid token` |

**Leak vectors (tracked files):**
- `Tests/Scenario/ScenarioTestHelper.psm1` (lines 13, 18, 28 — since removed)
- `.github/workflows/integration.yml` (lines 242, 272 — since removed)
- `.claude/commands/implement.md`, `test-endpoint.md`, `netbox-api.md` (since rewritten)

All leak vectors are clean in the current tree — tokens were removed from the
live files but remain in history.

**Why historic-only:** Probing all four tokens against their issuers returned
`Invalid token` / `Invalid v1 token` / `Invalid v2 token` on 2026-04-18.
Someone (or rotation policy on the instance) has already revoked them.

**Bonus observation (positive):** when zwqg's old token was probed, the
response was:

```
{"detail":"Source IP 162.158.38.28 is not permitted to authenticate using this token."}
```

NetBox's per-token IP allowlist was actively defending zwqg. Even during the
window the token was live, an attacker outside the allowed egress IP would
have been blocked before reaching NetBox's auth layer. Worth enabling on all
production-hosted NetBox tokens.

**Remediation applied in this PR:**

1. `.gitleaks.toml` — custom rules for NetBox v1 (40-hex) and v2 (`nbt_*`)
   token patterns, plus a project-wide allowlist for known test placeholders
   (docker-compose bootstrap token `0123456789abcdef…`, `nbt_yourKey.*`,
   Slack webhook template, etc).
2. `.gitleaks-baseline.json` — snapshot of the 8 historic findings so CI
   doesn't flag them repeatedly (only new secrets will fail the build).
3. `.github/workflows/secret-scan.yml` — gitleaks-action runs on every push
   and PR to dev/main, uses the repo's config + baseline.
4. `.pre-commit-config.yaml` — gitleaks pre-commit hook for local-first
   prevention (opt-in: `pip install pre-commit && pre-commit install`).

**Local hygiene cleanup (not in this PR — gitignored files):**

`.netboxps.config.ps1` and `.netbox-test-vms.ps1` previously held the same
(now-dead) tokens as string literals. These have been refactored locally to
read from `$env:NETBOX_*` — which direnv already loads from `.env` — so the
tokens live in exactly one place (`.env`, gitignored, never committed).

### 2. [MEDIUM] Direct `${{ inputs.* }}` interpolation into PowerShell run-blocks

**Files:** `.github/workflows/pre-release-validation.yml`

- Line 252: `Threshold = ${{ inputs.coverage_threshold }}` (inside PowerShell
  here-string passed to pwsh)
- Line 257: `$threshold = [int]"${{ inputs.coverage_threshold }}"`
- Line 834: `$version = "${{ inputs.version }}"`
- Line 835: `$skipIntegration = "${{ inputs.skip_integration }}" -eq 'true'`
- Line 836: `$coverageThreshold = [int]"${{ inputs.coverage_threshold }}"`

**Attack surface:** `workflow_dispatch` inputs have `type: string` without
format validation. A maintainer (or attacker who gained write access) running
this workflow with a crafted `version` like:

    99"; Remove-Item -Recurse -Force /; #

would produce executable PowerShell code at interpolation time:

    $version = "99"; Remove-Item -Recurse -Force /; #"

**Risk rating:** MEDIUM — requires repo `write` access to trigger
`workflow_dispatch`, so the attacker is already partially trusted. But the
"trick a maintainer into pasting a crafted version string" scenario is real.

**Remediation (future PR):** switch to env-var indirection. Pattern:

```yaml
- name: Run
  env:
    INPUT_VERSION: ${{ inputs.version }}
    INPUT_COVERAGE: ${{ inputs.coverage_threshold }}
  shell: pwsh
  run: |
    $version = $env:INPUT_VERSION
    $coverageThreshold = [int]$env:INPUT_COVERAGE
```

Env-var interpolation is done by the shell at runtime, so the value is a
literal string — no code-injection vector.

### 3. [MEDIUM] Tag-based GitHub Actions references not pinned to SHA

**Files:** all workflows except the 3 that already SHA-pin `docker/setup-buildx-action@8d2750c68a42…`.

Unpinned:
- `actions/checkout@v4` (×11 references)
- `actions/upload-artifact@v4` (×12)
- `actions/cache@v4` (×2)
- `actions/github-script@v7` (×2)
- `actions/download-artifact@v4` (×2)

**Mitigating factor:** all are `actions/*` (GitHub-owned org). A compromise
here would be a major supply-chain event affecting millions of repos;
GitHub's own internal hardening makes this less likely than for third-party
actions. But SHA pinning is still the recommended baseline per OpenSSF
Scorecard.

**Remediation (future PR):** pin to SHA + enable Dependabot for the
`github-actions` ecosystem so SHAs get auto-bumped on new releases:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### 4. [LOW] VPN ValidateSets expose deprecated crypto algorithms

**Files:**
- `Functions/VPN/IKEProposal/New-NBVPNIKEProposal.ps1` (unchanged since before PR #377)
- `Functions/VPN/IPSecProposal/New-NBVPNIPSecProposal.ps1` (unchanged)
- `Functions/VPN/Tunnel/New-NBVPNTunnel.ps1` — PR #399 added `pptp` to Encapsulation ValidateSet
- `Functions/VPN/IKEProposal/New-NBVPNIKEProposal.ps1` — PR #399 added `dsa-signatures` to Authentication_Method

Deprecated values currently accepted:
- `hmac-md5` (MD5 — cryptographically broken, still ok for HMAC per NIST but deprecated)
- `hmac-sha1` (SHA-1 — weakened, NIST allows via SP 800-131A through 2030)
- `3des-cbc` (112-bit effective, NIST deprecated end-2023)
- `des-cbc` (56-bit, brute-forceable)
- `pptp` tunnel (MS-CHAPv2+RC4, cryptographically broken)
- `dsa-signatures` (legacy, rarely used in modern IKEv2)

**Why these exist:** PowerNetbox is a *documentation* tool for NetBox, not a
crypto-negotiation layer. If a user has legacy PPTP/3DES VPN infrastructure,
they need to be able to document it in NetBox. Refusing to accept these
values would break parity with NetBox's ChoiceSets.

**Risk rating:** LOW (informational) — no actual crypto happens in the
cmdlet; values are stored as metadata by NetBox server-side.

**Optional future hardening:** emit a `Write-Warning` at runtime when a user
selects a deprecated algorithm:

```powershell
$deprecated = @('hmac-md5', '3des-cbc', 'des-cbc', 'pptp', 'dsa-signatures')
if ($Encryption_Algorithm -in $deprecated) {
    Write-Warning "Algorithm '$Encryption_Algorithm' is cryptographically deprecated. Consider migrating."
}
```

### 5. [LOW] `workflow_dispatch` inputs use `type: string` without constraint

**Files:** all 4 workflows with `workflow_dispatch`.

Inputs like `netbox_version`, `version`, `test_versions`, `branching_version`
use `type: string` with no format enforcement. Free-form strings flow into
env vars and then into shell / `docker buildx build` commands (low injection
risk — env-var expansion is safe — but a `type: choice` constraint would
also catch typos at dispatch time).

**Remediation (future PR):** where the valid set is enumerable, use
`type: choice`:

```yaml
netbox_version:
  description: 'Netbox Docker image tag'
  required: false
  default: 'v4.5.8-4.0.2'
  type: choice
  options:
    - 'v4.5.8-4.0.2'
    - 'v4.4.10-3.4.2'
    - 'v4.3.7-3.2.1'
```

### 6. [INFO] No regressions in central crypto/auth code

Verified across the PR #377 → HEAD delta (`git diff a533bdf..HEAD`):

- **`Functions/Helpers/InvokeNetboxRequest.ps1`:** only additions are branch-
  context hints on 401/403 messages (#384). No changes to auth header
  construction, retry logic, TLS, or error redaction.
- **`Functions/Helpers/Get-NBRequestHeaders.ps1`:** `nbt_` prefix detection
  for v1/v2 auth scheme is correct.
- **`Functions/Setup/Set-NBCipherSSL.ps1`:** explicitly enables TLS 1.2
  (and 1.3 if available on .NET 4.8+); SSL 3.0 / TLS 1.0 / TLS 1.1 are
  excluded. Scoped to PS Desktop 5.1 only — PS Core uses modern TLS by
  default.
- **`Functions/Setup/Connect-NBAPI.ps1`:**
  - `$Scheme` defaults to `https`
  - Emits `Write-Warning` when HTTP is used: *"Your API token will be transmitted in plaintext"* (PR #377)
  - `SkipCertificateCheck` is opt-in `[switch]`
  - When `SkipCertificateCheck` + PS 7.4, `AllowInsecureRedirect` is set and
    warned about (PR #377 left this as warning-level, not error — correct)
- **`Wait-NBBranch`** (new cmdlet, PR #386): no direct crypto, wraps existing
  `Get-NBBranch` calls. Clean.
- **`AssertNBMutualExclusiveParam`** (new helper, PR #397/400): validation-
  only; no auth or crypto surface.

### 7. [INFO] Random/entropy usage

`Get-Random` is used once in `InvokeNetboxRequest.ps1:306` to compute jitter
for retry backoff. This is retry-timing randomization, not cryptographic
randomness — non-CSPRNG is appropriate here. No change needed.

## Artefacts added in this PR

| File | Purpose |
|---|---|
| `.gitleaks.toml` | Custom rules for v1/v2 NetBox tokens + project-wide allowlist |
| `.gitleaks-baseline.json` | Snapshot of 8 historic (dead-token) findings to ignore |
| `.github/workflows/secret-scan.yml` | CI gate: gitleaks on every push / PR |
| `.pre-commit-config.yaml` | Opt-in local gitleaks pre-commit hook |
| `docs/superpowers/reviews/2026-04-18-security-delta-review.md` | This document |

## Recommended follow-up PRs (not part of this review)

1. **Harden `pre-release-validation.yml` workflow-dispatch inputs**
   (finding #2) — small, isolated, ~5-line diff per step. Medium priority.
2. **SHA-pin `actions/*` references + add Dependabot** (finding #3) —
   mechanical; runs across all 8 workflows. Medium priority.
3. **Optional: runtime deprecation warnings on VPN crypto algorithms**
   (finding #4) — low-value but friendly UX nudge. Low priority.
4. **`type: choice` for enumerable `workflow_dispatch` inputs** (finding #5) —
   small ergonomic improvement. Low priority.

## What was *not* reviewed

- **Server-side NetBox configuration.** This review covers PowerNetbox (the
  PowerShell client) only. Harden the NetBox instance's TLS, cookie flags,
  and CORS settings separately.
- **Dependencies.** Pester, PSScriptAnalyzer versions are out of scope here;
  GitHub dependabot already tracks them.
- **Git history rewriting.** The 4 dead tokens remain in commits
  `ef1726d4`, `02c3b95`, `a449cfaa`, `8044791c`. Because the tokens are
  revoked, a `git filter-repo` rewrite would churn everyone's clones with
  no security benefit. Skipped.
