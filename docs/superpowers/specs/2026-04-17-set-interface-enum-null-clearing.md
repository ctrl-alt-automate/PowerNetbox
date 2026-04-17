---
title: Null-clearing for enum string parameters on Set-NBDCIMInterface
status: approved
date: 2026-04-17
predecessor: PR #398 (Interface parameters — deferred this scope item)
---

# Set-NBDCIMInterface — null-clearing for enum string parameters

## Context

PR #398 added 9 nullable numeric parameters to `Set-NBDCIMInterface` using the `[Nullable[T]]` pattern so callers can pass `$null` to clear the server-side value via PATCH. That pattern doesn't extend to string parameters with `[ValidateSet]` — PowerShell coerces `$null` to `""` at bind time and then ValidateSet rejects the empty string.

This spec closes that gap for the five enum-string parameters on `Set-NBDCIMInterface`:

- `-Duplex`
- `-POE_Mode`
- `-POE_Type`
- `-RF_Role`
- `-Mode`

## Decision — Option B (empty-string sentinel)

During the brainstorm, an initial preference for `[AllowNull()]` (Option A) was empirically disproven: `[AllowNull()] [ValidateSet(...)] [string]$X` + `-X $null` throws `"" does not belong to the set`. PowerShell coerces `$null` to `""` before ValidateSet runs.

**Approved pattern (Option B):**

```powershell
[AllowEmptyString()]
[ValidateSet('full', 'half', 'auto', '', IgnoreCase = $true)]
[string]$Duplex
```

- User writes `Set-NBDCIMInterface -Id 42 -Duplex ''` to clear the server-side value.
- In the function's `process {}` block, a single-pass loop translates empty-string sentinel to `$null` for the 5 enum parameters.
- `BuildURIComponents` then writes `$null` to the body hashtable; `ConvertTo-Json` serializes it as `null` correctly on both PS 5.1 and PS 7 (verified empirically — same mechanism as the 9 numeric nullable parameters from PR #398).

The result on the wire: `PATCH /api/dcim/interfaces/42/` with body `{"duplex": null}` — which NetBox accepts as "clear this field".

### Rejected alternatives

- **Option A** (`[AllowNull()]`): empirically doesn't work with `[string]` + `[ValidateSet]` combination; PowerShell binding layer rejects it.
- **Option E** (drop `[ValidateSet]` entirely): breaks with project convention that every enum parameter has client-side validation; removes Get-Help discoverability and tab completion for valid values.
- **Option F** (defer indefinitely): acceptable but leaves the gap documented-not-fixed; Option B is cheap enough that shipping it is preferable.

## Scope

**Single function modified:** `Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1`

**Five parameters updated:**

| Parameter | Current ValidateSet | New ValidateSet |
|---|---|---|
| `Duplex` | `'full','half','auto'` | `'full','half','auto',''` + `[AllowEmptyString()]` |
| `POE_Mode` | `'pd','pse'` | `'pd','pse',''` + `[AllowEmptyString()]` |
| `POE_Type` | 8-value set | 8 values + `''` + `[AllowEmptyString()]` |
| `RF_Role` | `'ap','station'` | `'ap','station',''` + `[AllowEmptyString()]` |
| `Mode` | 9-value set (title-case + lower + legacy numeric) | 9 values + `''` + `[AllowEmptyString()]` |

All `IgnoreCase = $true` attributes preserved.

**One new code block in `process {}`:**

Inserted after the existing Mode translation switch, before the call to `BuildURIComponents`:

```powershell
# Translate empty-string sentinel to $null for the 5 clearable enum params.
# Users pass '' to clear a field server-side; BuildURIComponents +
# ConvertTo-Json emit "field": null on the wire, which NetBox PATCH accepts.
$clearableEnums = @('Duplex', 'POE_Mode', 'POE_Type', 'RF_Role', 'Mode')
foreach ($clearable in $clearableEnums) {
    if ($PSBoundParameters.ContainsKey($clearable) -and $PSBoundParameters[$clearable] -eq '') {
        $PSBoundParameters[$clearable] = $null
    }
}
```

Placement matters: Mode has an existing translation switch (PR #398) that skips when Mode is `IsNullOrWhiteSpace`, so an empty-string Mode isn't translated to `'access'`. The new block runs after that switch, so Mode's `''` passes through and becomes `$null` in the body.

## Tests

5 new tests in `Tests/DCIM.Interfaces.Tests.ps1`, in a new `Context "Set-NBDCIMInterface enum null-clearing (#398 follow-up)"` nested inside the existing `Context "Set-NBDCIMInterface"`:

```powershell
It "Should send null when -Duplex '' is passed" {
    $Result = Set-NBDCIMInterface -Id 42 -Duplex ''
    $Result.Body | Should -Match '"duplex"\s*:\s*null'
}
# ... same pattern for POE_Mode, POE_Type, RF_Role, Mode
```

Asserts the JSON body contains the literal `"<field>": null` pattern. Matches the regex style already used by the 9 numeric null-clearing tests added in PR #398.

## Verification checklist

1. `Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1` → all green (baseline + 5 new)
2. `Invoke-Pester ./Tests/ -ExcludeTagFilter Integration,Live,Scenario` → full regression green
3. Filter-exclusion auditor → 0 findings (no ValidateSet is drift-relevant here — we're ADDING `''`, not a NetBox enum value)
4. PSScriptAnalyzer on the modified file → 0 new findings
5. Existing positive enum tests (`-Duplex 'auto'`, `-POE_Mode 'pse'`, etc.) still pass — adding `''` to ValidateSet doesn't affect existing valid values

## Release impact

Non-breaking. `-Duplex ''` previously threw `ValidateSet` error; now clears the field. Users who relied on that error to detect invalid input should migrate to catching `-Duplex $null` (which still throws) or pre-validating.

Candidate for next patch release (v4.5.8.2 or bundle with other work into v4.5.9.0).

## Out of scope

- Null-clearing for enum string parameters on **other** Set functions (only `Set-NBDCIMInterface` here). If demand surfaces, extend in a follow-up.
- Refactoring the sentinel logic into a shared helper — 5-line loop per function is simpler than a helper for now; if more Set functions adopt this, extract later.
- Client-side detection of "`-Duplex $null` was meant" — PowerShell's string coercion makes this unreachable from the cmdlet; document the `''` idiom in `.NOTES`.
