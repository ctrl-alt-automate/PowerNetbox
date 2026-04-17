---
title: DCIM Interface — additional parameters (#394) + Type drift fix (#392 item 2)
status: approved
date: 2026-04-17
tracking_issues:
  - "#394 — add missing parameters to New/Set-NBDCIMInterface (community request by @mkarel)"
  - "#392 item 2 — Get-NBDCIMInterface -Type drift (104 missing types)"
community_pr_context: PR #396 (closed 2026-04-17, reimplementation tracked here)
---

# DCIM Interface Parameters + Get-Type Drift — Design

## Context

### Community request

Matt Karel (@mkarel) filed issue #394 requesting 21 missing parameters on `New-NBDCIMInterface` and `Set-NBDCIMInterface` to reach 100% API coverage relative to the NetBox web UI. He also submitted PR #396 with an initial implementation in 4 commits. Per the project's established external-PR handling pattern (previously applied to his PR #366 → Device Bay depopulation fix in v4.5.3.2), PR #396 was closed with a thank-you + reimplementation commitment. This spec captures the reimplementation plan.

### Bundled fix (#392 item 2)

Because this work touches the `Functions/DCIM/Interfaces/` file cluster, we opportunistically fix `Get-NBDCIMInterface -Type` ValidateSet drift in the same PR. That ValidateSet is currently out of sync with `New-`/`Set-NBDCIMInterface -Type` by **104 missing interface types** (216 actual vs 112 in Get). Users cannot filter existing devices by newer types like 100GBASE, 400GBASE, 800GBASE, 1.6TbE.

## Decisions

### New parameters (21)

All applied to both `New-NBDCIMInterface` (Single parameter set) and `Set-NBDCIMInterface`, unless noted otherwise:

| Parameter | Type | Notes |
|---|---|---|
| `Label` | `[string]` | Physical label |
| `Parent` | `[uint64]` (New) / `[Nullable[uint64]]` (Set) | Parent interface ID (for subinterfaces) |
| `Bridge` | `[uint64]` (New) / `[Nullable[uint64]]` (Set) | Bridge interface ID |
| `Speed` | `[uint64]` (New) / `[Nullable[uint64]]` (Set) | Kbps |
| `Duplex` | `[string]` | `ValidateSet 'full','half','auto'` |
| `Mark_Connected` | `[bool]` | |
| `WWN` | `[string]` | `ValidatePattern '^([0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$'` (8-group FC WWN) |
| `VDCS` | `[uint64[]]` | Virtual Device Context **IDs** (NetBox M2M relation — expects IDs, not names) |
| `POE_Mode` | `[string]` | `ValidateSet 'pd','pse'` |
| `POE_Type` | `[string]` | `ValidateSet 'type1-ieee802.3af','type2-ieee802.3at','type3-ieee802.3bt','type4-ieee802.3bt','passive-24v-2pair','passive-24v-4pair','passive-48v-2pair','passive-48v-4pair'` |
| `Vlan_Group` | `[uint64]` | NetBox VLAN group **ID** (not name) |
| `QinQ_SVLAN` | `[uint64]` (New) / `[Nullable[uint64]]` (Set) | Service VLAN ID |
| `VRF` | `[uint64]` | NetBox VRF **ID** (not route distinguisher string) |
| `RF_Role` | `[string]` | `ValidateSet 'ap','station'` |
| `RF_Channel` | `[string]` | Free-form string (channel name like `2.4g-1-2412-22`) |
| `RF_Channel_Frequency` | `[int]` (New) / `[Nullable[int]]` (Set) | MHz, `ValidateRange(1, 1000000)` |
| `RF_Channel_Width` | `[int]` (New) / `[Nullable[int]]` (Set) | MHz, `ValidateRange(1, 10000)` |
| `TX_Power` | `[int]` (New) / `[Nullable[int]]` (Set) | dBm |
| `Primary_MAC_Address` | `[uint64]` (New) / `[Nullable[uint64]]` (Set) | NetBox MAC address record ID |
| `Owner` | `[uint64]` (New) / `[Nullable[uint64]]` (Set) | NetBox owner (user/team) ID |
| `Changelog_Message` | `[string]` | Free-form changelog entry |

`Tags` already exists on `Set-NBDCIMInterface` as `[object[]]`. Added to `New-NBDCIMInterface` in the same pattern.

**Type corrections relative to @mkarel's PR #396** (his initial choices, then our decision):

| Parameter | @mkarel | Decision | Rationale |
|---|---|---|---|
| `Vlan_Group` | `[string]` | `[uint64]` | NetBox API expects the group's object ID, not the name |
| `VRF` | `[string]` | `[uint64]` | NetBox API expects the VRF's object ID, not the Route Distinguisher string |
| `VDCS` | `[string[]]` | `[uint64[]]` | NetBox M2M relation expects object IDs |
| `Owner` | `[Int64]` | `[uint64]` | Consistent with all other NetBox object ID parameters in PowerNetbox |
| `Duplex.IgnoreCase` | `$false` | `$true` | Consistent with every other `[ValidateSet]` in the module |
| `POE_Mode.IgnoreCase` | `$false` | `$true` | Same |
| `RF_Role.IgnoreCase` | `$false` | `$true` | Same |

### Mode parameter — Q-in-Q addition (conservative)

NetBox 4.2+ added `q-in-q` as a valid Interface Mode value. @mkarel's PR added this, but also (a) flipped `IgnoreCase` to `$false` and (b) dropped the title-case legacy values (`'Access'`, `'Tagged'`, `'Tagged All'`). Both changes break backward compatibility for existing PowerNetbox users.

**Conservative approach** (this spec):
- Add `'q-in-q'` and `'Q-in-Q'` (title-case variant) and `400` (legacy numeric code, if it exists) to the ValidateSet.
- Keep `IgnoreCase = $true`.
- Extend the `begin {}` translation block to map `'Q-in-Q' → 'q-in-q'` and `'400' → 'q-in-q'` alongside the existing `'Access' → 'access'`, etc.

This ensures any pre-existing script using `-Mode 'Access' | 'Tagged' | 'Tagged All'` continues working without modification.

**Exclusions file update:** `scripts/validateset-parity-exclusions.txt` already suppresses `Mode` parity drift because of the translation layer. The comment about "this also suppresses the `q-in-q` gap" (in #392) becomes obsolete once we add `q-in-q` — we'll update the comment accordingly but keep the exclusion (the translation layer itself is still legitimate).

### Null-clearing (deferred from scope)

NetBox accepts `null` on PATCH to clear nullable fields. For numeric fields this spec supports clearing via `[Nullable[uint64]]` / `[Nullable[int]]` — passing `$null` explicitly sends `null` in the JSON body.

For enum string fields (`Duplex`, `POE_Mode`, `POE_Type`, `RF_Role`, `Mode`), clearing requires an `AllowEmptyString()` + empty-string-in-ValidateSet pattern (@mkarel's approach) or a custom `[AllowNull()]` handler. Both add complexity:
- The empty-string pattern complicates every positive and negative test for those parameters
- The `[AllowNull()]` pattern requires BuildURIComponents to distinguish "not supplied" from "supplied as null"

This spec **does not implement enum null-clearing**. Instead, a follow-up issue `#(TBD post-merge)` will be opened to track that as a separate, focused change. Users who need to clear enum fields in the meantime can use bulk update via direct REST or wait for the follow-up.

### Get-NBDCIMInterface -Type drift fix (#392 item 2)

The `Get-NBDCIMInterface` function declares a `-Type` parameter for filtering, with a much smaller `[ValidateSet]` than `New-` and `Set-`. Per #392 item 2: **synchronize** the three by copying the full 216-type ValidateSet from `Set-NBDCIMInterface.ps1:36` to `Get-NBDCIMInterface.ps1`. Plus add the new `q-in-q` Mode if `Get-NBDCIMInterface -Mode` is affected (it is — same file cluster, same fix).

After this, running `scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.7` should show: **17 findings → 16 findings** (item 2 of #392 closed).

## Architecture

No new functions. No new helpers. Parameter additions to existing functions, test additions to existing test file, one-line additions to two other function files, one exclusions-file comment update.

```
Functions/DCIM/Interfaces/
├── Get-NBDCIMInterface.ps1        ← -Type ValidateSet sync (#392 item 2)
├── New-NBDCIMInterface.ps1        ← +21 parameters in Single set
└── Set-NBDCIMInterface.ps1        ← +21 parameters, mirroring New

Tests/
└── DCIM.Interfaces.Tests.ps1      ← +~62 tests

scripts/
└── validateset-parity-exclusions.txt  ← update Mode comment
```

### Bulk mode interaction

`New-NBDCIMInterface` has a `Single` and `Bulk` parameter set. Bulk mode takes a `PSCustomObject` via pipeline. New parameters are only declared in `Single` mode; in `Bulk` mode they must be passed as properties on the input object (same as existing bulk behavior). The `Send-NBBulkRequest` passthrough in the `process {}` block forwards all properties, so bulk users can set `label`, `poe_mode`, etc. on their input objects without code changes here.

### Pipeline semantics (Set)

`Set-NBDCIMInterface` accepts `[uint64]$Id` via `ValueFromPipelineByPropertyName`. The new parameters don't change this. Common pattern for updating many interfaces stays:

```powershell
Get-NBDCIMDevice -Name 'sw01' |
    Get-NBDCIMInterface -Device_Id {$_.id} |
    Where-Object { $_.type -eq '10gbase-x-sfpp' } |
    Set-NBDCIMInterface -POE_Mode 'pse' -POE_Type 'type3-ieee802.3bt'
```

## Components

### Commit 1 — `feat: add 21 parameters to New-NBDCIMInterface (#394)`

**Files:**
- `Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1` — add parameter declarations + `.PARAMETER` help blocks
- `Tests/DCIM.Interfaces.Tests.ps1` — ~21 positive tests + ~4 ValidateSet negative tests in `Context "New-NBDCIMInterface"`

**Credit:** `Co-Authored-By: Matt Karel <mkarel@gmail.com>`

### Commit 2 — `feat: add 21 parameters to Set-NBDCIMInterface (#394)`

**Files:**
- `Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1` — add parameter declarations (with `[Nullable[T]]` for numeric nullable fields) + `.PARAMETER` help blocks
- `Tests/DCIM.Interfaces.Tests.ps1` — ~21 positive tests + ~4 ValidateSet negative tests + ~5 null-clearing tests for numeric fields in `Context "Set-NBDCIMInterface"`

**Credit:** `Co-Authored-By: Matt Karel <mkarel@gmail.com>`

### Commit 3 — `fix: add Q-in-Q Mode value to New/Set-NBDCIMInterface`

**Files:**
- `Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1` — extend Mode ValidateSet + begin-block translations
- `Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1` — same
- `Tests/DCIM.Interfaces.Tests.ps1` — 4 new Mode tests (`-Mode 'q-in-q'`, `-Mode 'Q-in-Q'` translates, `-Mode '400'` translates, invalid value throws)
- `scripts/validateset-parity-exclusions.txt` — update the Mode-related comment to reflect that q-in-q is now present

### Commit 4 — `fix: sync Get-NBDCIMInterface -Type ValidateSet with New/Set (#392 item 2)`

**Files:**
- `Functions/DCIM/Interfaces/Get-NBDCIMInterface.ps1` — replace the shorter -Type ValidateSet with the full 216-type list (copied verbatim from `Set-NBDCIMInterface.ps1`)
- `Tests/DCIM.Interfaces.Tests.ps1` — 3 new tests in `Context "Get-NBDCIMInterface"` exercising a representative sample of the newly-added types (e.g., `800gbase-x-qsfpdd`, `1.6tbase-kr8`, `200gbase-sr4`)

## Test strategy

### Per-parameter pattern (positive)

For every new parameter, add one `It` block that:
1. Calls the function with the parameter set to a realistic valid value
2. Asserts the resulting mock call has the parameter's API key in its URI (Get) or body (New/Set)

Example:
```powershell
It "Should pass -POE_Mode in the request body" {
    $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Mode 'pse'
    $body = $Result.Body | ConvertFrom-Json
    $body.poe_mode | Should -Be 'pse'
}
```

### ValidateSet negative tests

For each of the 4 new enum parameters (`Duplex`, `POE_Mode`, `POE_Type`, `RF_Role`), one test:
```powershell
It "Should reject invalid -POE_Mode value" {
    { New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Mode 'invalid' } |
        Should -Throw
}
```

### Null-clearing tests (Set only)

For each `[Nullable[uint64]]` / `[Nullable[int]]` parameter on `Set-`:
```powershell
It "Should send null when -Parent is explicitly null" {
    $Result = Set-NBDCIMInterface -Id 42 -Parent $null
    $body = $Result.Body | ConvertFrom-Json
    $body.parent | Should -BeNullOrEmpty
    # Specifically: verify null token in JSON, not absence of key
    $Result.Body | Should -Match '"parent"\s*:\s*null'
}
```

### Mode tests

| Input | Expected body value |
|---|---|
| `-Mode 'q-in-q'` | `"mode":"q-in-q"` |
| `-Mode 'Q-in-Q'` | `"mode":"q-in-q"` (translated) |
| `-Mode 'Access'` (regression) | `"mode":"access"` (pre-existing) |
| `-Mode 'invalid'` | Throws |

### Get-Type drift tests

Three probe tests on `Get-NBDCIMInterface -Type <newly-added>` verifying:
- URI contains `type=<value>`
- No ValidateSet rejection (parameter accepted)

## Verification checklist (pre-PR)

1. `Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1` → all green (~62 new tests pass)
2. `Invoke-Pester ./Tests/ -ExcludeTagFilter Integration,Live,Scenario` → full regression, zero failures
3. `pwsh -NoProfile -File ./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.7` → 17 findings → 16 findings (item 2 of #392 closed)
4. `Invoke-ScriptAnalyzer` on the 3 production files → zero new findings
5. `git log --oneline fix/silent-filter-combination..HEAD` shows 4 feat/fix commits + this spec as the first commit

## Migration / user-facing notes

### Release notes (v4.5.8.0)

```markdown
### v4.5.8.0 (YYYY-MM-DD)

**21 new interface parameters on New/Set-NBDCIMInterface (#394)**

Proposed and initial implementation by @mkarel (original PR #396). Adds full
NetBox API coverage for:
- label, parent, bridge, speed, duplex, mark_connected
- wwn, vdcs, poe_mode, poe_type
- vlan_group, qinq_svlan, vrf
- rf_role, rf_channel, rf_channel_frequency, rf_channel_width, tx_power
- primary_mac_address, owner, changelog_message, tags (New only — already on Set)
- Plus `q-in-q` value on the Mode parameter (NetBox 4.2+)

**Bug fix: Get-NBDCIMInterface -Type ValidateSet drift (#392 item 2)**

Synchronized with New/Set counterparts — 104 previously-missing interface types
now filterable, including all 100/200/400/800GBASE and 1.6TbE variants.
```

### Breaking change surface

**None.** All new parameters are optional. The Mode parameter's existing values (`'Access'`, `'Tagged'`, `'Tagged All'`, `'100'`, `'200'`, `'300'`) keep their original behavior. The `IgnoreCase = $true` semantics are preserved.

The Get-Type drift fix is strictly expansive — any previously-valid value still validates. Previously-rejected values now accepted.

### Known limitations / follow-up work

- **Null-clearing for enum string fields** (`Duplex`, `POE_Mode`, etc.) not supported. Follow-up issue to be opened post-merge tracking this feature request.
- **Primary_MAC_Address** requires the MAC address record to exist in NetBox beforehand (i.e., created via `New-NBDCIMMACAddress`). We do not auto-resolve from a MAC string.

## Out of scope

- Empty-string / null-clearing for enum string fields (deferred to a separate issue)
- New cmdlets like `Add-NBTag` / `Remove-NBTag` (mentioned in #395 as a 4.6-era feature)
- Other `-Type` drift items from #392 (VPN Tunnel Encapsulation, Rack Status, etc. — each gets its own PR)
- Changes to `Get-NBDCIMInterface` parameters other than `-Type` (e.g. filter synonyms or -Mode drift — if needed, separate follow-up)

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Mode-translation logic regression breaks existing scripts | Low | Regression test retaining all pre-existing values (`'Access'`, `'100'`, etc.) in same run |
| Parity tool picks up new false positives | Low-Medium | Run after commit 3, update exclusions file deliberately if any new PN-legitimate patterns surface |
| Null-clearing tests flaky on PS 5.1 vs PS 7 JSON serialization | Low | Memory confirms `ConvertTo-Json` produces `null` on both (Device Bay fix precedent from v4.5.3.2) |
| mkarel's `Primary_MAC_Address` ValidatePattern tighter than NetBox API | Low | Use his exact pattern `'^([0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$'` for `WWN` only — `Primary_MAC_Address` is an ID, no pattern needed |
| WWN format validation too strict (refuses dashes, dots, no-separator) | Medium | NetBox accepts multiple formats server-side; pattern normalized to `':'`-separated 8-group canonical form — if users report rejection, follow-up broadens |

## References

- Design predecessor: `docs/superpowers/specs/2026-04-16-filter-exclusion-design.md` (same workflow pattern)
- Community origin: issue #394 (mkarel), closed PR #396 (mkarel, 4 commits)
- Related parity tool: `scripts/Verify-ValidateSetParity.ps1` (PR #391)
- Bundled fix tracker: issue #392 item 2
- Previous external PR by same contributor: PR #366 → v4.5.3.2 Device Bay fix (same closure-and-reimplement pattern)
- NetBox API reference: `/api/dcim/interfaces/` with PATCH body accepting all 21 fields
