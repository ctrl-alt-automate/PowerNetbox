---
title: "#392 HIGH-severity ValidateSet drift batch — 6 fixes"
status: approved
date: 2026-04-17
tracking_issue: "#392 items 1, 3, 4, 5, 6, 7 from the HIGH-severity table"
---

# #392 HIGH-severity drift batch — Design

## Context

Issue #392 tracks 17 ValidateSet drift findings from `scripts/Verify-ValidateSetParity.ps1` (PR #391). Item 2 (`Get-NBDCIMInterface -Type`) was closed in PR #398. This spec covers the remaining 6 HIGH-severity items — parameters where the ValidateSet is narrower than NetBox's actual enum set, so users cannot supply legitimate API values through PowerNetbox.

All 6 fixes are **strictly expansive**: add new values to existing ValidateSets, preserve every pre-existing value, no breaking changes, no behavior change for callers already on the supported subset.

## Decisions

### Scope

| # | Function(s) | Parameter | Current values | Values to add |
|---|---|---|---|---|
| 1 | `New/Set-NBVPNTunnel` | `-Encapsulation` | `ipsec-transport, ipsec-tunnel, ip-ip, gre` | `l2tp, openvpn, pptp, wireguard` |
| 3 | `New-NBVPNIKEProposal` | `-Authentication_Method` | `preshared-keys, certificates` | `rsa-signatures, dsa-signatures` |
| 4 | `Get/New/Set-NBVirtualMachine` | `-Status` | `offline, active, planned, staged, failed, decommissioning` | `paused` |
| 5 | `Get/New/Set-NBDCIMRack` | `-Status` | `active, planned, reserved, deprecated` | `available` |
| 6 | `New/Set-NBEventRule` | `-Action_Type` | `webhook, script` | `notification` |
| 7 | `New-NBVirtualMachineInterface` | `-Mode` | `access, tagged, tagged-all` | `q-in-q` |

Total: **12 production files modified** (2 + 1 + 3 + 3 + 2 + 1) + test file updates.

### Structure

- **1 PR, 6 commits** — one per item — for clean git-blame and review isolation
- Commit message format: `fix: add <values> to <function(s)> -<Param> ValidateSet (#392 item <N>)`
- No `Co-Authored-By` — maintainer-internal fixes, not community contributions
- Each commit green on its own (TDD RED → GREEN → COMMIT cadence)

### Subtleties

**VM `-Status`** — preserve `IgnoreCase = $true` (consistent with rest of VM-related ValidateSets).

**VMInterface `-Mode`** — simpler than `DCIMInterface -Mode`. No legacy numeric codes (`'100'`/`'200'`/`'300'`), no title-case translation. Just append `'q-in-q'`. The DCIMInterface Mode complexity (PR #398) was historical; VMInterface Mode never accumulated that baggage.

**Ordering convention** — new values append at the end of the existing list (minimal diff, matches #398's approach on `Get-NBDCIMInterface -Type`).

**IgnoreCase preservation** — where the current ValidateSet already has `IgnoreCase = $true`, keep it. Where it doesn't, don't add it (minimal scope).

### Parity tool target

Pre-PR: parity tool reports 17 actionable findings.
Post-merge: should report **5 findings** (12 per-function entries closed across 6 issue items):
- VPN/Tunnel/{New,Set}-NBVPNTunnel.ps1 :: -Encapsulation → 2 entries removed
- VPN/IKEProposal/New-NBVPNIKEProposal.ps1 :: -Authentication_Method → 1 entry removed
- Virtualization/VirtualMachine/{Get,New,Set}-NBVirtualMachine.ps1 :: -Status → 3 entries removed
- DCIM/Racks/{Get,New,Set}-NBDCIMRack.ps1 :: -Status → 3 entries removed
- Extras/EventRules/{New,Set}-NBEventRule.ps1 :: -Action_Type → 2 entries removed
- Virtualization/VirtualMachineInterface/New-NBVirtualMachineInterface.ps1 :: -Mode → 1 entry removed

## Architecture

No new files. No new helpers. Each commit adds 1–4 string literals to a `[ValidateSet(...)]` declaration and appends 1–2 tests per modified function to the relevant test file.

```
Functions/VPN/Tunnel/          ← commit 1: +4 values to Encapsulation
Functions/VPN/IKEProposal/     ← commit 2: +2 values to Authentication_Method
Functions/Virtualization/VirtualMachine/      ← commit 3: +1 value to Status
Functions/DCIM/Racks/          ← commit 4: +1 value to Status
Functions/Extras/EventRules/   ← commit 5: +1 value to Action_Type
Functions/Virtualization/VirtualMachineInterface/  ← commit 6: +1 value to Mode

Tests/VPN.Tests.ps1                                         ← +tests for commits 1-2
Tests/Virtualization.Tests.ps1                              ← +tests for commits 3, 6
Tests/DCIM.Racks.Tests.ps1                                  ← +tests for commit 4
Tests/Extras.Tests.ps1                                      ← +tests for commit 5
```

## Test strategy

Per parameter, per function affected, add one positive test asserting the new value round-trips through the URI/body:

```powershell
It "Should accept -Encapsulation 'wireguard'" {
    $Result = New-NBVPNTunnel -Name 'tnl' -Status 'active' -Encapsulation 'wireguard'
    ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'wireguard'
}
```

One test per new value × function that accepts that parameter:

| Commit | Tests |
|---|---|
| 1 (Encapsulation) | 4 values × 2 functions (New, Set) = 8 tests |
| 2 (Auth_Method) | 2 values × 1 function = 2 tests |
| 3 (VM Status) | 1 value × 3 functions (Get, New, Set) = 3 tests |
| 4 (Rack Status) | 1 value × 3 functions = 3 tests |
| 5 (Action_Type) | 1 value × 2 functions = 2 tests |
| 6 (VMInterface Mode) | 1 value × 1 function = 1 test |

**Total: 19 new tests.**

## Verification checklist (pre-PR)

1. `Invoke-Pester ./Tests/` filtered to affected files → all green
2. Full unit regression excluding Integration/Live/Scenario → 2261 baseline + 19 = 2280, zero failures
3. `pwsh -NoProfile -File ./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.8` → 17 → 5 findings
4. PSScriptAnalyzer on 12 changed production files → zero new findings

## Release impact

Non-breaking. Candidate for next patch/minor release (v4.5.8.1 or bundled with Branch 2 + 3 in v4.5.9.0).

**Release notes line (draft):**

> **6 HIGH-severity ValidateSet drift fixes (#392 items 1, 3-7)**
> Adds the missing NetBox API enum values on VPN Tunnel encapsulation (`l2tp`, `openvpn`, `pptp`, `wireguard`), VPN IKE Proposal authentication (`rsa-signatures`, `dsa-signatures`), VM status (`paused`), Rack status (`available`), EventRule action type (`notification`), and VMInterface mode (`q-in-q`). Strictly additive; every previously-accepted value still validates. Parity tool drift count 17 → 11.

## Out of scope

- **#392 items 7-8 (MEDIUM catalog adds)**: Cable Type 9 coax values, FrontPort/RearPort 11 FC+USB values. Separate PR.
- **#392 item 9 (LOW)**: DCIMInterfaceConnection Connection_Status `decommissioning`. The endpoint is the old-style interface connection, superseded by cables. Research needed before fixing.
- **Other #397 PR-2 scope** (remaining 121 Get function mutex rollout): separate branch.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Adding a value that NetBox doesn't actually accept | Very low | Values come directly from NetBox's `choices.py` source as surfaced by the parity tool |
| Breaking existing callers | None | Purely additive ValidateSet |
| Ordering change breaks a test that asserts specific array contents | Low | Append to end; no test asserts the full ValidateSet literal |
| Commit 3's IgnoreCase attribute accidentally dropped | Low | Explicit in spec; subagent reviewer verifies |

## References

- Issue #392 (parent tracker, initial audit from parity tool)
- PR #391 (`scripts/Verify-ValidateSetParity.ps1` tooling)
- PR #398 (closed item 2 — `Get-NBDCIMInterface -Type` sync)
- PR #390 (closed Cable_Profile — precedent for this pattern)
