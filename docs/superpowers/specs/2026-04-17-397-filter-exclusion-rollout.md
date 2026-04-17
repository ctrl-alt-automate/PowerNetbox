---
title: "#397 PR-2 — mutex assertion rollout to 121 Get functions + AST auditor"
status: approved
date: 2026-04-17
predecessor: PR #397 (pilot) and design spec docs/superpowers/specs/2026-04-16-filter-exclusion-design.md
---

# #397 PR-2 — Filter-exclusion rollout + auditor

## Context

PR #397 (merged as `7948512`) introduced the `AssertNBMutualExclusiveParam` helper and applied it to 3 pilot Get functions (`Get-NBDCIMDevice`, `Get-NBIPAMAddress`, `Get-NBVPNTunnel`). This spec covers **PR-2** — the mechanical rollout to the remaining ~121 Get functions, the parallel `IncludeConfigContext` guard on `Get-NBVirtualMachine`, the AST-based `Verify-FilterExclusion.ps1` auditor, and its CI integration.

Per the PR-1 design spec (`2026-04-16-filter-exclusion-design.md` §4 and §7), the audit pattern mirrors `Verify-ValidateSetParity.ps1` (PR #391).

## Decisions

### Scope breakdown

1. **Auditor** (`scripts/Verify-FilterExclusion.ps1`): standalone PowerShell script that AST-parses `Functions/**/Get-NB*.ps1`, identifies Get functions that declare all three `Brief`/`Fields`/`Omit` parameters, and reports any where the `AssertNBMutualExclusiveParam` call is missing from the `process {}` block.

2. **Rollout to 121 Get functions**: add the 4-line `AssertNBMutualExclusiveParam` call at the top of `process {}` for every Get function with all three filter parameters. Use a one-shot PowerShell migration leveraging the auditor's detection logic.

3. **`Get-NBVirtualMachine` special case**: parallel to `Get-NBDCIMDevice` from PR #397, the auto-omit of `config_context` must be guarded by `$inProjectionMode` so it only fires outside `-Brief`/`-Fields` mode. 5 new special-case tests in `Tests/Virtualization.Tests.ps1`.

4. **Per-function `.NOTES` help text**: one-line note added to every Get function that has all three filter parameters:
   ```
   .NOTES
       The -Brief, -Fields, and -Omit parameters are mutually exclusive.
   ```
   Inserted just before the `.LINK` block to match existing help-ordering conventions.

5. **CI job**: new job in `.github/workflows/test.yml` that runs `Verify-FilterExclusion.ps1 -FailOnMismatch` so future Get functions cannot regress the invariant.

### Commit structure

Four commits, ordered so each leaves the repo in a consistent state:

| # | Commit | Scope | Rationale |
|---|---|---|---|
| 1 | `feat: add Verify-FilterExclusion.ps1 auditor script` | New script + unit tests | Standalone, reviewable in isolation |
| 2 | `feat: enforce Brief/Fields/Omit mutex on 121 Get functions (#397 PR-2)` | ~121 `.ps1` modifications + `Get-NBVirtualMachine` guard + 5 VM special-case tests | The big mechanical commit |
| 3 | `docs: per-function .NOTES about Brief/Fields/Omit mutual exclusion` | Help-block additions across 124 Get functions | Kept separate so code-only diff stays clean |
| 4 | `ci: add filter-exclusion auditor job to test.yml` | CI integration | Landing last ensures CI stays green after commit 2 + 3 |

### Migration implementation

Mechanical. One-shot PowerShell script (not committed — run once during implementation):

```powershell
$findings = & ./scripts/Verify-FilterExclusion.ps1 -OutputFormat Json -SkipCI | ConvertFrom-Json
foreach ($finding in $findings) {
    # Locate the `process {` block, insert the 4-line assertion right after its opening brace
    # Preserve existing indentation and blank-line conventions per function
}
```

**Key subtlety**: per PR #397 code-review feedback (CLAUDE.md memory), each target function's existing blank-line convention between `)` and `process {` varies. The migration must detect and preserve each function's style rather than imposing a uniform template.

### Auditor algorithm

Per design spec §4:

1. Glob `Functions/**/Get-NB*.ps1`.
2. Parse each file with `[System.Management.Automation.Language.Parser]::ParseFile(...)`.
3. For each `FunctionDefinitionAst`:
   a. Read declared parameter names from `ParamBlockAst.Parameters`.
   b. If the set `{Brief, Fields, Omit}` is not a subset, **skip** (function doesn't need the assertion).
   c. Find all `CommandAst` nodes in the function body.
   d. Report a finding if no `CommandAst` has `CommandElements[0]` with value `AssertNBMutualExclusiveParam` AND a `-Parameters` argument containing all three names (`'Brief'`, `'Fields'`, `'Omit'`).
4. Output:
   - Default: human-readable table (`File`, `Function`, `Status`).
   - `-OutputFormat Json`: machine-readable for CI consumption.
   - `-FailOnMismatch`: exit code ≠ 0 if any findings.
5. Exemptions file (`scripts/filter-exclusion-exemptions.txt`) reserved for future edge cases; on initial rollout, empty.

### VM special case parallels

Mirror exactly what PR #398 did for `Get-NBDCIMDevice` Mode handling, applied to `Get-NBVirtualMachine`:

```powershell
process {
    AssertNBMutualExclusiveParam `
        -BoundParameters $PSBoundParameters `
        -Parameters 'Brief', 'Fields', 'Omit'

    $inProjectionMode = $PSBoundParameters.ContainsKey('Brief') -or
                        $PSBoundParameters.ContainsKey('Fields')

    $omitFields = @()
    if ($PSBoundParameters.ContainsKey('Omit')) {
        $omitFields += $Omit
    }
    if (-not $IncludeConfigContext -and -not $inProjectionMode) {
        $omitFields += 'config_context'
    }
    # ... rest unchanged
}
```

5 new special-case tests matching the Device pattern:
- `-Brief`: `?brief=True`, no `omit=config_context`
- `-Fields id,name`: `?fields=...`, no `omit=config_context`
- `-Omit comments`: `?omit=comments,config_context` (merged)
- `-IncludeConfigContext -Brief`: `?brief=True` (IncludeConfigContext silently ignored)
- no flags: `?omit=config_context` (default preserved)

### `.NOTES` insertion placement

All 124 Get functions with all three filter parameters get a `.NOTES` block inserted just before `.LINK` (the end of the help block). Single line:

```powershell
.NOTES
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.

.LINK
```

Functions that already have a `.NOTES` block get the line appended (not replaced).

### Test counts

| Source | Count |
|---|---|
| Auditor unit tests (`Tests/AuditorTests.Tests.ps1`) | 6 (detection scenarios) |
| VM special-case tests (`Tests/Virtualization.Tests.ps1`) | 5 |
| Pilot tests from PR #397 (already exist) | 12 |
| **New tests from this PR** | **11** |

Baseline: **2280** (post-#399 on dev). Target: **2291**.

### CI job

Add to `.github/workflows/test.yml` alongside PSScriptAnalyzer:

```yaml
filter-exclusion-audit:
  name: Filter-exclusion audit
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: docker/setup-buildx-action@...
    - name: Run auditor
      shell: pwsh
      run: ./scripts/Verify-FilterExclusion.ps1 -FailOnMismatch
```

## Architecture

```
scripts/
├── Verify-FilterExclusion.ps1          ← NEW: auditor (mirrors Verify-ValidateSetParity.ps1 structure)
└── filter-exclusion-exemptions.txt     ← NEW: exemptions file (initially empty)

Functions/**/Get-NB*.ps1                ← 121 files: +4-line AssertNBMutualExclusiveParam call
Functions/Virtualization/VirtualMachine/Get-NBVirtualMachine.ps1
                                        ← Special: +$inProjectionMode guard on config_context auto-omit

Tests/
├── AuditorTests.Tests.ps1              ← NEW: 6 unit tests for the auditor
└── Virtualization.Tests.ps1            ← +5 VM special-case tests

Functions/**/Get-NB*.ps1 (all 124)      ← +.NOTES help text line

.github/workflows/test.yml              ← +filter-exclusion-audit job
```

## Verification checklist (pre-PR)

1. `Invoke-Pester ./Tests/ -ExcludeTagFilter Integration,Live,Scenario` → 2280 baseline + 11 new = **2291 passed / 0 failed**
2. `./scripts/Verify-FilterExclusion.ps1` → 0 findings
3. `./scripts/Verify-FilterExclusion.ps1 -FailOnMismatch` → exit code 0
4. `./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.8` → still 5 findings (unchanged; this PR doesn't touch ValidateSets)
5. PSScriptAnalyzer on new scripts + modified Get functions → 0 new findings

## Release impact

**Breaking change** (as flagged in PR #397 / v4.5.8.0 release notes). This PR expands the breaking-change surface from 3 pilot functions to all 124 Get functions with Brief/Fields/Omit. Users whose scripts silently combined any two of those parameters across *any* Get function will now see `ParameterBindingException` — but those scripts were already broken (one parameter's effect silently ignored).

Candidate for v4.5.9.0 minor release.

## Out of scope

- Enum null-clearing in Set functions (Branch 3 — `feat/set-interface-enum-null-clearing`)
- #392 MEDIUM catalog adds (Cable/FrontPort/RearPort Type lists)
- #392 LOW item (DCIMInterfaceConnection Connection_Status — endpoint possibly deprecated)
- Netbox 4.6.0-beta1 compat (#395 — explicitly deferred by user)
