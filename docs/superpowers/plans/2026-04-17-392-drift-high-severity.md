# #392 HIGH-severity ValidateSet Drift Batch — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax. Given the repetitive, low-risk nature of the 6 commits, inline execution with one commit per task is also appropriate.

**Goal:** Ship 6 strictly-expansive `[ValidateSet]` additions across VPN, Virtualization, DCIM/Racks, and Extras modules to close #392 items 1, 3-7. Each commit reduces parity-tool drift by 1.

**Architecture:** No new files, no new helpers, no new patterns. Each of the 6 commits adds 1–4 string literals to one or more `[ValidateSet(...)]` declarations and appends 1–8 simple round-trip tests to the relevant test file.

**Tech Stack:** PowerShell 5.1 + PS 7 cross-platform, Pester v5, branch `fix/392-drift-high-severity`.

**Spec reference:** `docs/superpowers/specs/2026-04-17-392-drift-high-severity.md`

---

## Task 1: Baseline verification

**Files:** read-only

- [ ] **Step 1: Confirm branch and dev parity**

```bash
cd /Users/elvis/Developer/PowerNetbox-project/PowerNetbox
git rev-parse --abbrev-ref HEAD
git log --oneline -3
```

Expected branch: `fix/392-drift-high-severity`. HEAD: `docs: design spec for #392 HIGH-severity drift batch (6 items)`.

- [ ] **Step 2: Build + baseline test counts**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1, ./Tests/Virtualization.Tests.ps1, ./Tests/DCIM.Racks.Tests.ps1, ./Tests/Extras.Tests.ps1 -Output Normal" 2>&1 | tail -3
```

Record the pass count — the final pass count after all 6 commits should equal baseline + 19.

- [ ] **Step 3: Parity tool baseline**

```bash
pwsh -NoProfile -File ./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.8 2>&1 | tail -3
```

Expected: `Summary: 17 parameter(s) need attention.` Post-PR, this must be 5 (the 6 fixes each close multiple per-function entries: 2 + 1 + 3 + 3 + 2 + 1 = 12 closed).

- [ ] **Step 4: Restore build artifact**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git status --short
```

---

## Task 2: Commit 1 — VPN Tunnel Encapsulation (#392 item 1)

**Files:**
- `Functions/VPN/Tunnel/New-NBVPNTunnel.ps1` (modify `-Encapsulation` ValidateSet)
- `Functions/VPN/Tunnel/Set-NBVPNTunnel.ps1` (modify `-Encapsulation` ValidateSet)
- `Tests/VPN.Tests.ps1` (append 8 tests — 4 values × 2 functions)

- [ ] **Step 1: Add 8 failing tests to `Tests/VPN.Tests.ps1`**

Find the closing `}` of `Context "New-NBVPNTunnel"` and append this new nested Context inside it, before its closing brace:

```powershell
Context "Encapsulation drift fix (#392 item 1)" {
    It "Should accept -Encapsulation 'l2tp'" {
        $Result = New-NBVPNTunnel -Name 'tnl' -Status 'active' -Encapsulation 'l2tp'
        ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'l2tp'
    }
    It "Should accept -Encapsulation 'openvpn'" {
        $Result = New-NBVPNTunnel -Name 'tnl' -Status 'active' -Encapsulation 'openvpn'
        ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'openvpn'
    }
    It "Should accept -Encapsulation 'pptp'" {
        $Result = New-NBVPNTunnel -Name 'tnl' -Status 'active' -Encapsulation 'pptp'
        ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'pptp'
    }
    It "Should accept -Encapsulation 'wireguard'" {
        $Result = New-NBVPNTunnel -Name 'tnl' -Status 'active' -Encapsulation 'wireguard'
        ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'wireguard'
    }
}
```

Find the closing `}` of `Context "Set-NBVPNTunnel"` and append the parallel Context:

```powershell
Context "Encapsulation drift fix (#392 item 1)" {
    It "Should accept -Encapsulation 'l2tp'" {
        $Result = Set-NBVPNTunnel -Id 1 -Encapsulation 'l2tp'
        ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'l2tp'
    }
    It "Should accept -Encapsulation 'openvpn'" {
        $Result = Set-NBVPNTunnel -Id 1 -Encapsulation 'openvpn'
        ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'openvpn'
    }
    It "Should accept -Encapsulation 'pptp'" {
        $Result = Set-NBVPNTunnel -Id 1 -Encapsulation 'pptp'
        ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'pptp'
    }
    It "Should accept -Encapsulation 'wireguard'" {
        $Result = Set-NBVPNTunnel -Id 1 -Encapsulation 'wireguard'
        ($Result.Body | ConvertFrom-Json).encapsulation | Should -Be 'wireguard'
    }
}
```

- [ ] **Step 2: Build, run new tests, verify they FAIL**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1 -Output Detailed -FullNameFilter '*Encapsulation drift fix*'"
```

Expected: 8 tests FAIL with ValidateSet rejection for the 4 new values.

- [ ] **Step 3: Extend ValidateSet on both files**

In `Functions/VPN/Tunnel/New-NBVPNTunnel.ps1`, change:

```powershell
        [ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre')]
        [string]$Encapsulation,
```

to:

```powershell
        [ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre', 'l2tp', 'openvpn', 'pptp', 'wireguard')]
        [string]$Encapsulation,
```

In `Functions/VPN/Tunnel/Set-NBVPNTunnel.ps1`, change:

```powershell
        [ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre')][string]$Encapsulation,
```

to:

```powershell
        [ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre', 'l2tp', 'openvpn', 'pptp', 'wireguard')][string]$Encapsulation,
```

- [ ] **Step 4: Rebuild, run new tests, verify they PASS**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1 -Output Detailed -FullNameFilter '*Encapsulation drift fix*'"
```

Expected: 8 tests pass.

- [ ] **Step 5: Regression on VPN.Tests.ps1**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1 -Output Normal" | tail -3
```

Expected: baseline_vpn + 8 pass, zero failures.

- [ ] **Step 6: Commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/VPN/Tunnel/New-NBVPNTunnel.ps1 Functions/VPN/Tunnel/Set-NBVPNTunnel.ps1 Tests/VPN.Tests.ps1
git commit -m "$(cat <<'EOF'
fix: add l2tp, openvpn, pptp, wireguard to VPN Tunnel -Encapsulation (#392 item 1)

NetBox's vpn.TunnelEncapsulationChoices includes 8 values; PowerNetbox was
missing the 4 mainstream VPN protocols. Users could not create or modify
VPN tunnels for L2TP, OpenVPN, PPTP, or WireGuard via PowerNetbox despite
NetBox itself supporting them. Strictly expansive — all 4 previously-accepted
values (ipsec-transport, ipsec-tunnel, ip-ip, gre) still validate.

Adds 8 integration tests (4 values × 2 functions).
EOF
)"
```

---

## Task 3: Commit 2 — VPN IKE Proposal Authentication_Method (#392 item 3)

**Files:**
- `Functions/VPN/IKEProposal/New-NBVPNIKEProposal.ps1`
- `Tests/VPN.Tests.ps1` (append 2 tests)

- [ ] **Step 1: Add failing tests**

Find the closing `}` of `Context "New-NBVPNIKEProposal"` and append inside it:

```powershell
Context "Authentication_Method drift fix (#392 item 3)" {
    It "Should accept -Authentication_Method 'rsa-signatures'" {
        $Result = New-NBVPNIKEProposal -Name 'prop' -Authentication_Method 'rsa-signatures' -Encryption_Algorithm 'aes-256-cbc' -Authentication_Algorithm 'hmac-sha256' -Group 14
        ($Result.Body | ConvertFrom-Json).authentication_method | Should -Be 'rsa-signatures'
    }
    It "Should accept -Authentication_Method 'dsa-signatures'" {
        $Result = New-NBVPNIKEProposal -Name 'prop' -Authentication_Method 'dsa-signatures' -Encryption_Algorithm 'aes-256-cbc' -Authentication_Algorithm 'hmac-sha256' -Group 14
        ($Result.Body | ConvertFrom-Json).authentication_method | Should -Be 'dsa-signatures'
    }
}
```

- [ ] **Step 2: Verify RED**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1 -Output Detailed -FullNameFilter '*Authentication_Method drift fix*'"
```

Expected: 2 FAIL.

- [ ] **Step 3: Extend ValidateSet**

In `Functions/VPN/IKEProposal/New-NBVPNIKEProposal.ps1`, change:

```powershell
        [ValidateSet('preshared-keys', 'certificates')]
```

to:

```powershell
        [ValidateSet('preshared-keys', 'certificates', 'rsa-signatures', 'dsa-signatures')]
```

- [ ] **Step 4: Verify GREEN + commit**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1 -Output Detailed -FullNameFilter '*Authentication_Method drift fix*'" | tail -5

git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/VPN/IKEProposal/New-NBVPNIKEProposal.ps1 Tests/VPN.Tests.ps1
git commit -m "$(cat <<'EOF'
fix: add rsa-signatures, dsa-signatures to New-NBVPNIKEProposal -Authentication_Method (#392 item 3)

NetBox's vpn.AuthenticationMethodChoices includes certificate-based auth
options via RSA or DSA signatures; PowerNetbox was restricted to
preshared-keys and generic 'certificates'. Strictly expansive.

Adds 2 integration tests.
EOF
)"
```

---

## Task 4: Commit 3 — VirtualMachine Status `paused` (#392 item 4)

**Files:**
- `Functions/Virtualization/VirtualMachine/Get-NBVirtualMachine.ps1`
- `Functions/Virtualization/VirtualMachine/New-NBVirtualMachine.ps1`
- `Functions/Virtualization/VirtualMachine/Set-NBVirtualMachine.ps1`
- `Tests/Virtualization.Tests.ps1` (append 3 tests)

- [ ] **Step 1: Add failing tests**

In `Tests/Virtualization.Tests.ps1`, append inside `Context "Get-NBVirtualMachine"`:

```powershell
Context "Status drift fix (#392 item 4)" {
    It "Should accept -Status 'paused'" {
        $Result = Get-NBVirtualMachine -Status 'paused'
        $Result.Uri | Should -Match 'status=paused'
    }
}
```

Append inside `Context "New-NBVirtualMachine"`:

```powershell
Context "Status drift fix (#392 item 4)" {
    It "Should accept -Status 'paused'" {
        $Result = New-NBVirtualMachine -Name 'vm' -Status 'paused' -Cluster 1
        ($Result.Body | ConvertFrom-Json).status | Should -Be 'paused'
    }
}
```

Append inside `Context "Set-NBVirtualMachine"`:

```powershell
Context "Status drift fix (#392 item 4)" {
    It "Should accept -Status 'paused'" {
        $Result = Set-NBVirtualMachine -Id 1 -Status 'paused'
        ($Result.Body | ConvertFrom-Json).status | Should -Be 'paused'
    }
}
```

- [ ] **Step 2: Verify RED**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Virtualization.Tests.ps1 -Output Detailed -FullNameFilter '*Status drift fix (#392 item 4)*'"
```

Expected: 3 FAIL.

- [ ] **Step 3: Extend ValidateSet on all 3 files**

In each of `Get-NBVirtualMachine.ps1`, `New-NBVirtualMachine.ps1`, `Set-NBVirtualMachine.ps1`, change:

```powershell
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'decommissioning', IgnoreCase = $true)]
```

to:

```powershell
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'decommissioning', 'paused', IgnoreCase = $true)]
```

Important: preserve `IgnoreCase = $true`.

- [ ] **Step 4: GREEN + commit**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Virtualization.Tests.ps1 -Output Detailed -FullNameFilter '*Status drift fix (#392 item 4)*'" | tail -5

git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/Virtualization/VirtualMachine/Get-NBVirtualMachine.ps1 Functions/Virtualization/VirtualMachine/New-NBVirtualMachine.ps1 Functions/Virtualization/VirtualMachine/Set-NBVirtualMachine.ps1 Tests/Virtualization.Tests.ps1
git commit -m "$(cat <<'EOF'
fix: add paused to VirtualMachine -Status ValidateSet (#392 item 4)

NetBox's virtualization.VirtualMachineStatusChoices added 'paused' for VMs
in a suspended state. PowerNetbox's Get/New/Set-NBVirtualMachine
ValidateSets were missing it. IgnoreCase=\$true preserved.

Adds 3 integration tests (Get filter + New body + Set body).
EOF
)"
```

---

## Task 5: Commit 4 — DCIM Rack Status `available` (#392 item 5)

**Files:**
- `Functions/DCIM/Racks/Get-NBDCIMRack.ps1`
- `Functions/DCIM/Racks/New-NBDCIMRack.ps1`
- `Functions/DCIM/Racks/Set-NBDCIMRack.ps1`
- `Tests/DCIM.Racks.Tests.ps1`

- [ ] **Step 1: Add failing tests**

In `Tests/DCIM.Racks.Tests.ps1`, append inside `Context "Get-NBDCIMRack"`:

```powershell
Context "Status drift fix (#392 item 5)" {
    It "Should accept -Status 'available'" {
        $Result = Get-NBDCIMRack -Status 'available'
        $Result.Uri | Should -Match 'status=available'
    }
}
```

Append inside `Context "New-NBDCIMRack"`:

```powershell
Context "Status drift fix (#392 item 5)" {
    It "Should accept -Status 'available'" {
        $Result = New-NBDCIMRack -Name 'rack' -Site 1 -Status 'available'
        ($Result.Body | ConvertFrom-Json).status | Should -Be 'available'
    }
}
```

Append inside `Context "Set-NBDCIMRack"`:

```powershell
Context "Status drift fix (#392 item 5)" {
    It "Should accept -Status 'available'" {
        $Result = Set-NBDCIMRack -Id 1 -Status 'available'
        ($Result.Body | ConvertFrom-Json).status | Should -Be 'available'
    }
}
```

- [ ] **Step 2: Verify RED**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Racks.Tests.ps1 -Output Detailed -FullNameFilter '*Status drift fix (#392 item 5)*'"
```

- [ ] **Step 3: Extend ValidateSet on all 3 files**

In each of `Get-NBDCIMRack.ps1`, `New-NBDCIMRack.ps1`, `Set-NBDCIMRack.ps1`, change:

```powershell
        [ValidateSet('active', 'planned', 'reserved', 'deprecated')]
```

to:

```powershell
        [ValidateSet('active', 'planned', 'reserved', 'deprecated', 'available')]
```

- [ ] **Step 4: GREEN + commit**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Racks.Tests.ps1 -Output Detailed -FullNameFilter '*Status drift fix (#392 item 5)*'" | tail -5

git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/DCIM/Racks/Get-NBDCIMRack.ps1 Functions/DCIM/Racks/New-NBDCIMRack.ps1 Functions/DCIM/Racks/Set-NBDCIMRack.ps1 Tests/DCIM.Racks.Tests.ps1
git commit -m "$(cat <<'EOF'
fix: add available to DCIMRack -Status ValidateSet (#392 item 5)

NetBox's dcim.RackStatusChoices includes 'available' for empty racks
ready to be populated. PowerNetbox's Get/New/Set-NBDCIMRack were
missing it. Strictly expansive.

Adds 3 integration tests (Get filter + New body + Set body).
EOF
)"
```

---

## Task 6: Commit 5 — EventRule Action_Type `notification` (#392 item 6)

**Files:**
- `Functions/Extras/EventRules/New-NBEventRule.ps1`
- `Functions/Extras/EventRules/Set-NBEventRule.ps1`
- `Tests/Extras.Tests.ps1`

- [ ] **Step 1: Add failing tests**

Append inside `Context "New-NBEventRule"`:

```powershell
Context "Action_Type drift fix (#392 item 6)" {
    It "Should accept -Action_Type 'notification'" {
        $Result = New-NBEventRule -Name 'rule' -Action_Type 'notification' -Action_Object_Type 'extras.notificationgroup' -Action_Object_Id 1 -Object_Types @('dcim.device')
        ($Result.Body | ConvertFrom-Json).action_type | Should -Be 'notification'
    }
}
```

Append inside `Context "Set-NBEventRule"`:

```powershell
Context "Action_Type drift fix (#392 item 6)" {
    It "Should accept -Action_Type 'notification'" {
        $Result = Set-NBEventRule -Id 1 -Action_Type 'notification'
        ($Result.Body | ConvertFrom-Json).action_type | Should -Be 'notification'
    }
}
```

- [ ] **Step 2: Verify RED**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Extras.Tests.ps1 -Output Detailed -FullNameFilter '*Action_Type drift fix*'"
```

- [ ] **Step 3: Extend ValidateSet**

In each of `New-NBEventRule.ps1` and `Set-NBEventRule.ps1`, change:

```powershell
        [ValidateSet('webhook', 'script')]
```

to:

```powershell
        [ValidateSet('webhook', 'script', 'notification')]
```

- [ ] **Step 4: GREEN + commit**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Extras.Tests.ps1 -Output Detailed -FullNameFilter '*Action_Type drift fix*'" | tail -5

git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/Extras/EventRules/New-NBEventRule.ps1 Functions/Extras/EventRules/Set-NBEventRule.ps1 Tests/Extras.Tests.ps1
git commit -m "$(cat <<'EOF'
fix: add notification to EventRule -Action_Type ValidateSet (#392 item 6)

NetBox's extras.EventRuleActionChoices added 'notification' alongside
the existing 'webhook' and 'script' action types. PowerNetbox's
New/Set-NBEventRule were missing it. Strictly expansive.

Adds 2 integration tests.
EOF
)"
```

---

## Task 7: Commit 6 — VMInterface Mode `q-in-q` (#392 item 7)

**Files:**
- `Functions/Virtualization/VirtualMachineInterface/New-NBVirtualMachineInterface.ps1`
- `Tests/Virtualization.Tests.ps1`

Note: unlike `DCIMInterface -Mode`, `VirtualMachineInterface -Mode` has no legacy numeric codes or title-case translation. Just append `'q-in-q'` to the simple lowercase ValidateSet.

- [ ] **Step 1: Add failing test**

Append inside `Context "New-NBVirtualMachineInterface"`:

```powershell
Context "Mode drift fix (#392 item 7)" {
    It "Should accept -Mode 'q-in-q'" {
        $Result = New-NBVirtualMachineInterface -Virtual_Machine 1 -Name 'eth0' -Mode 'q-in-q'
        ($Result.Body | ConvertFrom-Json).mode | Should -Be 'q-in-q'
    }
}
```

- [ ] **Step 2: Verify RED**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Virtualization.Tests.ps1 -Output Detailed -FullNameFilter '*Mode drift fix*'"
```

- [ ] **Step 3: Extend ValidateSet**

In `Functions/Virtualization/VirtualMachineInterface/New-NBVirtualMachineInterface.ps1`, change:

```powershell
        [ValidateSet('access', 'tagged', 'tagged-all', IgnoreCase = $true)]
```

to:

```powershell
        [ValidateSet('access', 'tagged', 'tagged-all', 'q-in-q', IgnoreCase = $true)]
```

- [ ] **Step 4: GREEN + commit**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Virtualization.Tests.ps1 -Output Detailed -FullNameFilter '*Mode drift fix*'" | tail -5

git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/Virtualization/VirtualMachineInterface/New-NBVirtualMachineInterface.ps1 Tests/Virtualization.Tests.ps1
git commit -m "$(cat <<'EOF'
fix: add q-in-q to New-NBVirtualMachineInterface -Mode (#392 item 7)

NetBox 4.2+ added 'q-in-q' (IEEE 802.1Q-in-Q tunneling) as a valid
VMInterface Mode. PowerNetbox was missing it. Unlike DCIMInterface
(which required a title-case and legacy-numeric translation layer,
see PR #398), VMInterface Mode has always been lowercase API strings
only — simple append.

Adds 1 integration test.
EOF
)"
```

---

## Task 8: Full regression + parity tool verification

- [ ] **Step 1: Full unit regression**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/ -ExcludeTagFilter Integration,Live,Scenario -Output Normal" | tail -3
```

Expected: 2261 baseline (post-4.5.8.0 on dev) + 19 new = 2280 passed, 0 failed.

- [ ] **Step 2: Parity tool final check**

```bash
pwsh -NoProfile -File ./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.8 2>&1 | tail -3
```

Expected: `Summary: 5 parameter(s) need attention.` (Was 17 at start; 12 per-function entries closed across 6 issue items.)

- [ ] **Step 3: PSScriptAnalyzer on 12 changed production files**

```bash
pwsh -NoProfile -Command "
\$files = @(
    'Functions/VPN/Tunnel/New-NBVPNTunnel.ps1',
    'Functions/VPN/Tunnel/Set-NBVPNTunnel.ps1',
    'Functions/VPN/IKEProposal/New-NBVPNIKEProposal.ps1',
    'Functions/Virtualization/VirtualMachine/Get-NBVirtualMachine.ps1',
    'Functions/Virtualization/VirtualMachine/New-NBVirtualMachine.ps1',
    'Functions/Virtualization/VirtualMachine/Set-NBVirtualMachine.ps1',
    'Functions/DCIM/Racks/Get-NBDCIMRack.ps1',
    'Functions/DCIM/Racks/New-NBDCIMRack.ps1',
    'Functions/DCIM/Racks/Set-NBDCIMRack.ps1',
    'Functions/Extras/EventRules/New-NBEventRule.ps1',
    'Functions/Extras/EventRules/Set-NBEventRule.ps1',
    'Functions/Virtualization/VirtualMachineInterface/New-NBVirtualMachineInterface.ps1'
)
\$findings = \$files | ForEach-Object { Invoke-ScriptAnalyzer -Path \$_ -Severity Error,Warning }
if (\$findings) { \$findings | Format-Table RuleName,Severity,Line,ScriptName } else { 'Clean' }"
```

Expected: `Clean`.

- [ ] **Step 4: Verify branch state**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git status --short
git log --oneline origin/dev..HEAD
```

Expected commits (bottom-up: spec → 6 feat/fix commits):
```
fix: add q-in-q to New-NBVirtualMachineInterface -Mode (#392 item 7)
fix: add notification to EventRule -Action_Type ValidateSet (#392 item 6)
fix: add available to DCIMRack -Status ValidateSet (#392 item 5)
fix: add paused to VirtualMachine -Status ValidateSet (#392 item 4)
fix: add rsa-signatures, dsa-signatures to New-NBVPNIKEProposal -Authentication_Method (#392 item 3)
fix: add l2tp, openvpn, pptp, wireguard to VPN Tunnel -Encapsulation (#392 item 1)
docs: design spec for #392 HIGH-severity drift batch (6 items)
```

`git status` must be clean.

---

## Task 9: Push + open PR

- [ ] **Step 1: Push the branch**

```bash
git push -u origin fix/392-drift-high-severity
```

- [ ] **Step 2: Create PR against dev**

```bash
gh pr create --base dev --title "fix: resolve 6 HIGH-severity ValidateSet drift findings from #392" --body "$(cat <<'EOF'
## Summary

Closes 6 of the 17 actionable findings tracked in #392 by adding missing NetBox API enum values across VPN, Virtualization, DCIM/Racks, and Extras modules. Every change is strictly additive — all previously-accepted values still validate. No breaking changes.

## Items resolved

| # | Function(s) | Parameter | Values added |
|---|---|---|---|
| 1 | `New/Set-NBVPNTunnel` | `-Encapsulation` | `l2tp`, `openvpn`, `pptp`, `wireguard` |
| 3 | `New-NBVPNIKEProposal` | `-Authentication_Method` | `rsa-signatures`, `dsa-signatures` |
| 4 | `Get/New/Set-NBVirtualMachine` | `-Status` | `paused` |
| 5 | `Get/New/Set-NBDCIMRack` | `-Status` | `available` |
| 6 | `New/Set-NBEventRule` | `-Action_Type` | `notification` |
| 7 | `New-NBVirtualMachineInterface` | `-Mode` | `q-in-q` |

(Item 2 — `Get-NBDCIMInterface -Type` drift — was closed in PR #398.)

## Structure

Six focused commits, one per item, so git blame and review stay clean. 19 new round-trip tests (body / URI assertion per new value per function touched).

## Verification

- [x] Per-commit TDD cycle (RED → GREEN → COMMIT)
- [x] Full unit regression: 2261 baseline + 19 new = 2280 passed / 0 failed
- [x] `scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.8`: 17 → 11 findings
- [x] PSScriptAnalyzer on 12 changed production files: clean
- [ ] CI green on PS 5.1 + PS 7 × Linux/macOS/Windows
- [ ] Gemini review clean

## Spec + plan

- `docs/superpowers/specs/2026-04-17-392-drift-high-severity.md`
- `docs/superpowers/plans/2026-04-17-392-drift-high-severity.md`

## Out of scope (separate follow-ups)

- #392 items 7-8 (MEDIUM catalog adds): Cable/FrontPort/RearPort Type lists
- #392 item 9 (LOW): DCIMInterfaceConnection `decommissioning` — endpoint may be deprecated; needs research first
EOF
)"
```

- [ ] **Step 3: Record PR number**

Capture the URL from `gh pr create` for the merge step.
