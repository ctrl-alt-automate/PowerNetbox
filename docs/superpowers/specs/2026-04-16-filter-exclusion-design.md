---
title: Brief / Fields / Omit Mutual Exclusion
status: approved
date: 2026-04-16
tracking_issue: to be created post-approval
prs:
  - PR-1 — helper + pilot
  - PR-2 — rollout + auditor
---

# Brief / Fields / Omit Mutual Exclusion — Design

## Problem

PowerNetbox's 124 `Get-NB*` functions each expose three independent projection parameters:

- `-Brief` — request a minimal representation (`?brief=True`)
- `-Fields` — specify which fields to return (`?fields=a,b,c`)
- `-Omit` — exclude specific fields (`?omit=x,y`)

Today these can be combined in any way. `BuildURIComponents` writes each into the query string independently without cross-validation. Netbox applies them with undefined precedence (empirically `brief` wins over the others, `fields` and `omit` interact by set difference). Scripts that pass two of these flags get the result of one and silently ignore the other.

This is the "silent surprise" class of bug: the call works, but the caller's intent does not map to the response.

Gemini flagged the pattern in reviews three times across 2026; it has been on the future-refactoring list per project memory. This spec formalises the fix.

## Decision Summary

| Question | Choice |
|---|---|
| Which combinations are forbidden? | **All three are mutually exclusive (A)**. `-Brief` XOR `-Fields` XOR `-Omit`. |
| Validation mechanism? | **Runtime helper with terminating error (Option 2)**. No new ParameterSets. |
| Rollout | **Two-phase**. PR-1: helper + 3 pilots. PR-2: auditor + remaining 121 functions + docs. |
| Version impact | Minor bump (`v4.5.7.0` → `v4.5.8.0`). Breaking in error surface, not in successful behavior. |

Rejected alternatives:

- **Option A vs B (Fields+Omit allowed)**: rejected because the `fields - omit` intersection is exotic, users better served by picking one filter strategy, and Netbox's own documentation formulates the three as alternatives ("use X or Y").
- **ParameterSets (Option 1)**: rejected because the cartesian product of ByID/Query × Default/Brief/Fields/Omit requires 8 sets per function and ~992 additional `[Parameter(ParameterSetName=...)]` attributes on query filter params, with a cryptic built-in error message ("Parameter set cannot be resolved using the specified named parameters").
- **Warn-don't-error (Option C)**: rejected because the silent-surprise bug persists if we only warn.

## Architecture

Single validation pass executes before URI construction. One helper function, one call site per Get function:

```
User invocation
   │
   ▼
process { }
   │
   ├── AssertNBMutualExclusiveParam -BoundParameters $PSBoundParameters \
   │                                -Parameters 'Brief','Fields','Omit'
   │       ◆ throws ParameterBindingException if ≥2 supplied
   │
   ├── (existing) Build Segments, BuildURIComponents, BuildNewURI
   │
   └── InvokeNetboxRequest
```

The helper is **pure** (no I/O, no module state) and therefore unit-testable in isolation.

## Components

### 1. `AssertNBMutualExclusiveParam` helper

**Location:** `PowerNetbox/Functions/Helpers/AssertNBMutualExclusiveParam.ps1`
**Export policy:** Internal. No hyphen in name, consistent with `BuildURIComponents`, `BuildNewURI`, `InvokeNetboxRequest`, `GetNetboxAPIErrorBody`. Not exported in production build (`deploy.ps1 -Environment prod` filters by hyphenated names).
**Error behavior:** Terminating — `throw [System.Management.Automation.ParameterBindingException]`.

```powershell
function AssertNBMutualExclusiveParam {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$BoundParameters,

        [Parameter(Mandatory)]
        [ValidateCount(2, 10)]
        [string[]]$Parameters,

        [string]$HelpHint
    )

    $supplied = $Parameters | Where-Object { $BoundParameters.ContainsKey($_) }
    if ($supplied.Count -gt 1) {
        $joined = '-' + ($supplied -join ', -')
        $message = "Parameters $joined are mutually exclusive. Specify only one."
        if ($HelpHint) { $message += " $HelpHint" }
        throw [System.Management.Automation.ParameterBindingException]::new($message)
    }
}
```

**Design notes:**

- `[System.Collections.IDictionary]` accepts both `$PSBoundParameters` (a `Dictionary<string,object>`) and plain `Hashtable` — enables clean unit testing without mocking the cmdlet runtime.
- `[ValidateCount(2, 10)]` rejects nonsensical usage (0 or 1 parameter to check). Upper bound of 10 is generous; current use case is 3.
- `ParameterBindingException` is the semantically correct exception type — the defect is conceptually a parameter-binding issue, even if raised at runtime.
- `HelpHint` is optional and appended to the message. Leaves room for per-call-site guidance (e.g., "See Get-Help for -IncludeConfigContext").

### 2. Call-site pattern (standard Get function)

One-line insertion at the top of `process { }`, before `Write-Verbose`:

```powershell
process {
    AssertNBMutualExclusiveParam `
        -BoundParameters $PSBoundParameters `
        -Parameters 'Brief', 'Fields', 'Omit'

    Write-Verbose "Retrieving ..."
    switch ($PSCmdlet.ParameterSetName) { ... }
}
```

**Why `process {}` and not `begin {}`:** In `begin {}`, `$PSBoundParameters` contains only non-pipeline-bound parameters. Pipeline-bound `-Id` from `ValueFromPipelineByPropertyName` arrives per-object in `process {}`. Placing the assertion in `process {}` keeps its view consistent with how the rest of the function uses `$PSBoundParameters`.

**Scope:** 122 of 124 Get functions follow this pattern exactly. The remaining 2 (`Get-NBDCIMDevice`, `Get-NBVirtualMachine`) have special `IncludeConfigContext` handling — see §3.

Functions **without** `Brief`/`Fields`/`Omit` are left untouched:
- `Get-NBDCIMRackElevation`, `Get-NBDCIMConnectedDevice`, `Get-NBIPAMAvailableIP` — PR #343 already removed these parameters as inapplicable.

### 3. Special case: `IncludeConfigContext` interaction

`Get-NBDCIMDevice` and `Get-NBVirtualMachine` inject `config_context` into the `omit` list by default (performance optimisation — config_context rendering is 10-100× slower). The user opts in with `-IncludeConfigContext`.

With Option A (mutual exclusion), the auto-omit logic becomes conditional on not being in Brief or Fields mode:

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
    # Auto-omit config_context only when the user has not otherwise restricted
    # the projection. Brief returns minimal representations (config_context never
    # included). Fields explicitly selects what to return (user owns that choice).
    if (-not $IncludeConfigContext -and -not $inProjectionMode) {
        $omitFields += 'config_context'
    }
    # ... rest unchanged
}
```

**Behavior matrix:**

| User invocation | Query sent to Netbox | Rationale |
|---|---|---|
| `-Brief` | `?brief=True` | Minimal already; auto-omit unnecessary. |
| `-Fields id,name` | `?fields=id,name` | User-selected projection owns the result shape. |
| `-Omit comments` | `?omit=comments,config_context` | Merge user omit with performance default. |
| (no flags) | `?omit=config_context` | Default performance optimisation. |
| `-IncludeConfigContext` | (no omit) | Explicit opt-in. |
| `-IncludeConfigContext -Brief` | `?brief=True` | IncludeConfigContext is silently ignored (no-op in Brief mode). |
| `-Brief -Fields X` | — | **Throws `ParameterBindingException`**. |

**`IncludeConfigContext + Brief` silent no-op:** Decided during brainstorming. Alternative was `Write-Warning`. Chose silent because the switch has a well-defined semantic ("return config_context when it would otherwise be omitted") that is simply vacuous in Brief mode — no user action is wrong, nothing is worth logging.

### 4. Auditor script (PR-2)

**Location:** `PowerNetbox/scripts/Verify-FilterExclusion.ps1`
**Pattern:** Mirrors `Verify-ValidateSetParity.ps1` (PR #391). Same output format options, same CI-gating approach, same exemptions file convention.

**Algorithm:**

1. Glob `Functions/**/Get-NB*.ps1`.
2. Parse each file with `[System.Management.Automation.Language.Parser]::ParseFile(...)`.
3. For each `FunctionDefinitionAst`:
   a. Collect declared parameter names from `ParamBlockAst.Parameters`.
   b. If the set `{Brief, Fields, Omit}` is not a subset, skip (function doesn't need the assertion).
   c. Find all `CommandAst` nodes inside the function body. Check for a `CommandAst` whose `CommandElements[0]` is `AssertNBMutualExclusiveParam` and whose arguments include `-Parameters 'Brief','Fields','Omit'`.
   d. If not found, emit a finding.
4. Output:
   - Default: human-readable table (`File`, `Function`, `Status`).
   - `-OutputFormat Json`: machine-readable for CI consumption.
   - `-FailOnMismatch`: exit code ≠ 0 if any findings.
5. Exemptions file (`scripts/filter-exclusion-exemptions.txt`) for edge cases that the AST filter doesn't catch.

**CI integration:** New job in `.github/workflows/test.yml`, parallel to PSScriptAnalyzer. Fails the build when a new Get function lands without the assertion.

**Why AST over regex:** AST parsing correctly handles commented-out calls (`# AssertNBMutualExclusiveParam ...`), mistyped parameter lists (`-Parameters 'Brief','Wrong'`), and multi-line formatting. A regex would produce false positives on the first and false negatives on the second and third.

### 5. Test strategy

**5a. Unit tests for the helper** — `PowerNetbox/Tests/Unit/AssertNBMutualExclusiveParam.Tests.ps1` (~10 tests):

- Zero parameters from the list in `$BoundParameters` → no throw.
- Exactly one parameter from the list → no throw.
- Two parameters → throws `ParameterBindingException`; message contains both names prefixed with `-`.
- Three parameters → throws; message lists all three.
- `$HelpHint` is appended to the message when supplied.
- `ValidateCount(2, 10)` rejects calls with < 2 parameters.
- Case-sensitive name matching (`'Brief'` ≠ `'brief'`), consistent with `$PSBoundParameters` semantics.
- Accepts both `System.Collections.Generic.Dictionary[string,object]` and `Hashtable` for `$BoundParameters`.
- Empty/`$null` `$BoundParameters` → no throw.
- Exception is `ParameterBindingException`, not `ArgumentException` or generic `Exception`.

**5b. Pilot integration tests** — extended into existing test files for the 3 pilots (4 scenarios × 3 pilots = 12 tests):

For each of `Get-NBDCIMDevice`, `Get-NBIPAMAddress`, `Get-NBVPNTunnel`:

- `-Brief -Fields 'id'` → throws `ParameterBindingException`.
- `-Brief -Omit 'comments'` → throws.
- `-Fields 'id' -Omit 'name'` → throws.
- Control: `-Brief` alone → no throw, URI contains `brief=True`.

**5c. Special-case tests** for the two functions with `IncludeConfigContext` (5 tests per function):

In PR-1 — `Get-NBDCIMDevice` (part of the pilot set):

- `-Brief` → URI `?brief=True`, no `config_context` in omit.
- `-Fields id,name` → URI `?fields=id,name`, no `config_context` in omit.
- `-Omit comments` → URI `?omit=comments,config_context` (merged).
- `-IncludeConfigContext -Brief` → URI `?brief=True` (IncludeConfigContext silently ignored).
- No flags → URI `?omit=config_context` (default behavior preserved).

In PR-2 — `Get-NBVirtualMachine` (rolled out alongside the other 120 standard functions): same five scenarios, identical assertions.

**Mock layer:** `InvokeNetboxRequest` mock, consistent with 17 of 24 existing test files. Assertion throws before reaching the mock, so throw-path tests do not need mock setup.

**Total tests added:**
- PR-1: ~27 new tests (10 helper unit + 12 pilot integration + 5 special-case for Device).
- PR-2: ~5 new tests for VM special case + any regression tests the auditor surfaces.

### 6. Documentation & migration

**6a. `CLAUDE.md` "Recent Changes" section:**

```markdown
### v4.5.8.0 (date TBD)

**Breaking change: Brief, Fields, and Omit are now mutually exclusive (#XXX, PR-1 #YYY, PR-2 #ZZZ)**

- Previously, supplying `-Brief` with `-Fields` or `-Omit` silently sent all three
  to Netbox, which applied undefined precedence (brief typically won). The
  silently-ignored flag(s) produced results that did not match caller intent.
- Now throws `ParameterBindingException` with a message naming which parameters
  conflict, e.g. `"Parameters -Brief, -Fields are mutually exclusive. Specify only one."`
- Migration: pick one filter strategy per call.
  - Minimal: `-Brief`
  - Specific fields: `-Fields 'id','name','status'`
  - Default minus specific fields: `-Omit 'comments','description'`
- New internal helper: `AssertNBMutualExclusiveParam` (`Functions/Helpers/`).
- New CI guard: `scripts/Verify-FilterExclusion.ps1` (fails build if a Get
  function with Brief/Fields/Omit lacks the assertion).
```

**6b. Per-function help `.NOTES` block** — applied to all 124 functions via the PR-2 script:

```powershell
.NOTES
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
    Specify only one filter strategy per call.
```

**6c. PSGallery release notes:** one sentence linking to CHANGELOG.

### 7. Phased rollout

| Phase | PR | Deliverables | Size estimate | CI duration |
|---|---|---|---|---|
| 1 | PR-1 | Helper + 10 unit tests + 3 pilot functions (`Get-NBDCIMDevice`, `Get-NBIPAMAddress`, `Get-NBVPNTunnel`) + 12 pilot integration tests + 5 special-case tests for Device | ~300 prod + ~400 test | ~15 min |
| 2 | PR-2 | 121 remaining functions (scripted, includes `Get-NBVirtualMachine` with its special case) + 5 special-case tests for VM + `Verify-FilterExclusion.ps1` auditor + CI integration + help-text updates + CHANGELOG | ~500 mechanical prod + ~300 auditor + ~60 CI config | ~15 min + auditor job |

**Between PRs:** wait for PR-1 green CI + review; incorporate feedback on helper / pattern; PR-2 then is purely mechanical.

**Release flow:** follows `CLAUDE.md` standard — merge `dev` → `main`, version bump in `.psd1`, `gh release create vX.Y.Z.W --target main`.

## Out of scope

- Migrating `-Fields` / `-Omit` to ParameterSets-based validation. Explicitly considered and rejected (§Decision Summary).
- Tag-type unification for the 78 legacy Set/New functions (separate sub-project B3 in the refactor roadmap).
- Centralised `InvokeNetboxGet` helper refactor (separate sub-project B2).
- Changing behavior for the 3 functions that don't have Brief/Fields/Omit (RackElevation, ConnectedDevice, AvailableIP) — already correct per PR #343.
- Soft-deprecation period (warn for N versions, then error). Explicitly rejected: the current state already produces broken scripts, erroring immediately is more informative.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Downstream scripts rely on the silently-ignored behavior | Low-Medium | CHANGELOG is explicit about the breaking-ness; error message tells the user exactly what to remove. |
| Auditor script flags false positives | Low | AST-based parsing, exemption file for edge cases, mirrors proven `Verify-ValidateSetParity.ps1` approach. |
| Pilot functions' IncludeConfigContext edge case is implemented differently from standard pattern | Medium | Explicit §3 section in the spec. Test coverage for all 5 behavior-matrix rows. |
| `$PSBoundParameters` not populated as expected with pipeline input | Low | Call site is `process {}` not `begin {}`; tests include pipeline scenarios. |
| Rollout PR-2 merge conflicts with unrelated dev work | Medium | Script-driven application makes conflicts mechanical to resolve. Run rollout after any in-flight PRs merge. |

## Open questions

None at spec approval. All captured decisions are final pending user review.

## References

- Source files: `PowerNetbox/Functions/Helpers/BuildURIComponents.ps1`, `PowerNetbox/Functions/DCIM/Devices/Get-NBDCIMDevice.ps1`, `PowerNetbox/Functions/Virtualization/VirtualMachine/Get-NBVirtualMachine.ps1`.
- Related PRs: #297 (All/PageSize passthrough), #298 (Query/ByID parameter sets standardised), #343 (removed inapplicable Brief/Fields/Omit), #391 (`Verify-ValidateSetParity.ps1` — pattern reference for auditor).
- Netbox best practices: `netbox-best-practices/HUMAN.md:17,66-67` (formulates Brief/Fields/Omit as alternatives).
- Project memory: repeated Gemini review suggestions on Brief/Fields/Omit mutual exclusivity.
