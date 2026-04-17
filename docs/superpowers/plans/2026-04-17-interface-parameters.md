# DCIM Interface Parameters (#394) + Type Drift Fix (#392 item 2) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship 21 new parameters on `New-NBDCIMInterface` and `Set-NBDCIMInterface` (community request #394 by @mkarel), add `q-in-q` to the Mode ValidateSet, and synchronize `Get-NBDCIMInterface -Type` with the 216-type list from New/Set (closes #392 item 2).

**Architecture:** No new files. Parameter additions to three existing Interface functions in `Functions/DCIM/Interfaces/`, test additions to `Tests/DCIM.Interfaces.Tests.ps1`, one line-comment update in `scripts/validateset-parity-exclusions.txt`. Four logical commits, each atomic and test-green.

**Tech Stack:** PowerShell 5.1+ / 7 cross-platform, Pester v5, module built via `./deploy.ps1 -Environment dev -SkipVersion`, branch `feat/394-interface-parameters`.

**Spec reference:** `docs/superpowers/specs/2026-04-17-interface-parameters-design.md`

**Credit:** Commits 1 and 2 carry the code derived from @mkarel's closed PR #396. They must include a `Co-Authored-By: Matt Karel <mkarel@gmail.com>` trailer.

---

## Task 1: Baseline verification

**Files:** read-only

- [ ] **Step 1: Confirm branch**

```bash
cd /Users/elvis/Developer/PowerNetbox-project/PowerNetbox
git rev-parse --abbrev-ref HEAD
git log --oneline -3
```

Expected branch: `feat/394-interface-parameters`. Expected HEAD commit: design spec commit (latest), with dev's merge commit (PR-1, SHA `7948512`) two commits back.

- [ ] **Step 2: Build**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
```

Expected: "Deployment complete" on the final line.

- [ ] **Step 3: Baseline test counts for the files we'll touch**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Normal" 2>&1 | tail -3
```

Record the pass count (expected approximately 100). This is the baseline; our additions must add tests without breaking any existing ones.

- [ ] **Step 4: Run the parity tool baseline**

```bash
pwsh -NoProfile -File ./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.7 2>&1 | tail -30
```

Expected: 17 actionable drift findings. Note the exact line that reads `DCIM/Interfaces/Get-NBDCIMInterface.ps1 :: -Type` — this is the finding we close in commit 4.

- [ ] **Step 5: Restore build artifact**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git status --short
```

Expected: clean working tree.

---

## Task 2: New-NBDCIMInterface — add 21 parameters + 25 tests (Commit 1)

**Files:**
- Modify: `Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1`
- Modify: `Tests/DCIM.Interfaces.Tests.ps1` (append tests to `Context "New-NBDCIMInterface"`)

This task is TDD: write all new tests first, verify they fail, add the parameters, verify they pass.

- [ ] **Step 1: Append new tests to `Tests/DCIM.Interfaces.Tests.ps1`**

Open the file and find the closing `}` of `Context "New-NBDCIMInterface"` (search for `Context "New-NBDCIMInterface"` and trace down to its closing brace). Before that closing `}`, append this new nested `Context`:

```powershell
Context "New-NBDCIMInterface new parameters (#394)" {
    It "Should pass -Label in the request body" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Label 'port-01'
        ($Result.Body | ConvertFrom-Json).label | Should -Be 'port-01'
    }

    It "Should pass -Parent as the parent numeric ID" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0.100' -Type 'virtual' -Parent 42
        ($Result.Body | ConvertFrom-Json).parent | Should -Be 42
    }

    It "Should pass -Bridge as the bridge numeric ID" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'br0' -Type 'bridge' -Bridge 99
        ($Result.Body | ConvertFrom-Json).bridge | Should -Be 99
    }

    It "Should pass -Speed in Kbps" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Speed 1000000
        ($Result.Body | ConvertFrom-Json).speed | Should -Be 1000000
    }

    It "Should pass -Duplex with valid value 'full'" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Duplex 'full'
        ($Result.Body | ConvertFrom-Json).duplex | Should -Be 'full'
    }

    It "Should reject -Duplex with invalid value" {
        { New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Duplex 'invalid' } |
            Should -Throw
    }

    It "Should pass -Mark_Connected as boolean true" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Mark_Connected $true
        ($Result.Body | ConvertFrom-Json).mark_connected | Should -Be $true
    }

    It "Should pass -WWN with valid 8-group FC format" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'fc0' -Type '16gfc-sfpp' -WWN 'aa:bb:cc:dd:ee:ff:00:11'
        ($Result.Body | ConvertFrom-Json).wwn | Should -Be 'aa:bb:cc:dd:ee:ff:00:11'
    }

    It "Should reject -WWN with invalid format" {
        { New-NBDCIMInterface -Device 1 -Name 'fc0' -Type '16gfc-sfpp' -WWN 'not-a-wwn' } |
            Should -Throw
    }

    It "Should pass -VDCS as array of integer IDs" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -VDCS 10, 20, 30
        $body = $Result.Body | ConvertFrom-Json
        $body.vdcs | Should -Contain 10
        $body.vdcs | Should -Contain 20
        $body.vdcs | Should -Contain 30
    }

    It "Should pass -POE_Mode with valid value 'pse'" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Mode 'pse'
        ($Result.Body | ConvertFrom-Json).poe_mode | Should -Be 'pse'
    }

    It "Should reject -POE_Mode with invalid value" {
        { New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Mode 'invalid' } |
            Should -Throw
    }

    It "Should pass -POE_Type with valid value 'type3-ieee802.3bt'" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Type 'type3-ieee802.3bt'
        ($Result.Body | ConvertFrom-Json).poe_type | Should -Be 'type3-ieee802.3bt'
    }

    It "Should reject -POE_Type with invalid value" {
        { New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Type 'wrong' } |
            Should -Throw
    }

    It "Should pass -Vlan_Group as numeric ID" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Vlan_Group 77
        ($Result.Body | ConvertFrom-Json).vlan_group | Should -Be 77
    }

    It "Should pass -QinQ_SVLAN as numeric ID" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -QinQ_SVLAN 200
        ($Result.Body | ConvertFrom-Json).qinq_svlan | Should -Be 200
    }

    It "Should pass -VRF as numeric ID" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -VRF 5
        ($Result.Body | ConvertFrom-Json).vrf | Should -Be 5
    }

    It "Should pass -RF_Role with valid value 'ap'" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Role 'ap'
        ($Result.Body | ConvertFrom-Json).rf_role | Should -Be 'ap'
    }

    It "Should reject -RF_Role with invalid value" {
        { New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Role 'wrong' } |
            Should -Throw
    }

    It "Should pass -RF_Channel as free-form string" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Channel '2.4g-1-2412-22'
        ($Result.Body | ConvertFrom-Json).rf_channel | Should -Be '2.4g-1-2412-22'
    }

    It "Should pass -RF_Channel_Frequency in MHz" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Channel_Frequency 5180
        ($Result.Body | ConvertFrom-Json).rf_channel_frequency | Should -Be 5180
    }

    It "Should pass -RF_Channel_Width in MHz" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Channel_Width 80
        ($Result.Body | ConvertFrom-Json).rf_channel_width | Should -Be 80
    }

    It "Should pass -TX_Power in dBm" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -TX_Power 20
        ($Result.Body | ConvertFrom-Json).tx_power | Should -Be 20
    }

    It "Should pass -Primary_MAC_Address as numeric ID" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Primary_MAC_Address 12345
        ($Result.Body | ConvertFrom-Json).primary_mac_address | Should -Be 12345
    }

    It "Should pass -Owner as numeric ID" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Owner 7
        ($Result.Body | ConvertFrom-Json).owner | Should -Be 7
    }

    It "Should pass -Changelog_Message as free-form string" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Changelog_Message 'Initial provisioning'
        ($Result.Body | ConvertFrom-Json).changelog_message | Should -Be 'Initial provisioning'
    }

    It "Should pass -Tags as array of objects" {
        $tag = [PSCustomObject]@{ slug = 'production'; color = '00ff00' }
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Tags @($tag)
        $body = $Result.Body | ConvertFrom-Json
        $body.tags[0].slug | Should -Be 'production'
    }
}
```

- [ ] **Step 2: Build, run new tests — verify they fail**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*New-NBDCIMInterface new parameters*'" 2>&1 | tail -30
```

Expected: ~25 new tests fail. They fail because the parameters don't exist yet. Example failure: "A parameter cannot be found that matches parameter name 'Label'".

- [ ] **Step 3: Add all 21 new parameters to `Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1`**

Open the file. First, add new `.PARAMETER` help blocks to the comment-based help (just before the `.PARAMETER InputObject` block). Insert this block:

```powershell
.PARAMETER Label
    Physical label assigned to the interface.

.PARAMETER Parent
    Numeric ID of the parent interface (for subinterfaces).

.PARAMETER Bridge
    Numeric ID of the bridge this interface belongs to.

.PARAMETER Speed
    Speed of the interface in Kbps (e.g., 1000000 for 1Gbps).

.PARAMETER Duplex
    Duplex mode. One of: 'full', 'half', 'auto'.

.PARAMETER Mark_Connected
    If $true, the interface is marked as connected independent of cable state.

.PARAMETER WWN
    World Wide Name for Fibre Channel interfaces (8 groups of 2 hex digits,
    colon-separated, e.g. 'AA:BB:CC:DD:EE:FF:00:11').

.PARAMETER VDCS
    Array of Virtual Device Context numeric IDs.

.PARAMETER POE_Mode
    Power-over-Ethernet mode. One of: 'pd', 'pse'.

.PARAMETER POE_Type
    Power-over-Ethernet type. One of: 'type1-ieee802.3af', 'type2-ieee802.3at',
    'type3-ieee802.3bt', 'type4-ieee802.3bt', 'passive-24v-2pair',
    'passive-24v-4pair', 'passive-48v-2pair', 'passive-48v-4pair'.

.PARAMETER Vlan_Group
    Numeric ID of the VLAN group this interface belongs to.

.PARAMETER QinQ_SVLAN
    Numeric ID of the Service VLAN for QinQ.

.PARAMETER VRF
    Numeric ID of the VRF this interface belongs to.

.PARAMETER RF_Role
    Wireless RF role. One of: 'ap', 'station'.

.PARAMETER RF_Channel
    Wireless RF channel identifier (e.g. '2.4g-1-2412-22').

.PARAMETER RF_Channel_Frequency
    Wireless RF channel frequency in MHz (1-1000000).

.PARAMETER RF_Channel_Width
    Wireless RF channel width in MHz (1-10000).

.PARAMETER TX_Power
    Wireless transmit power in dBm.

.PARAMETER Primary_MAC_Address
    Numeric ID of the primary MAC address record. Use New-NBDCIMMACAddress to
    create a MAC address record, then pass its id here.

.PARAMETER Owner
    Numeric ID of the owning user or team.

.PARAMETER Changelog_Message
    Free-form message recorded in the Netbox changelog entry for this operation.

.PARAMETER Tags
    Array of tag objects (e.g. PSCustomObject with slug and color properties).

```

Then, in the `param()` block of `New-NBDCIMInterface`, locate the `[string]$Type,` parameter declaration (around line 106). Just after its closing `,`, insert these 21 new parameters:

```powershell
        [Parameter(ParameterSetName = 'Single')]
        [string]$Label,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Parent,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Bridge,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Speed,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('full', 'half', 'auto', IgnoreCase = $true)]
        [string]$Duplex,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$Mark_Connected,

        [Parameter(ParameterSetName = 'Single')]
        [ValidatePattern('^([0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$')]
        [string]$WWN,

        [Parameter(ParameterSetName = 'Single')]
        [uint64[]]$VDCS,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('pd', 'pse', IgnoreCase = $true)]
        [string]$POE_Mode,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('type1-ieee802.3af', 'type2-ieee802.3at', 'type3-ieee802.3bt', 'type4-ieee802.3bt', 'passive-24v-2pair', 'passive-24v-4pair', 'passive-48v-2pair', 'passive-48v-4pair', IgnoreCase = $true)]
        [string]$POE_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Vlan_Group,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$QinQ_SVLAN,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VRF,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('ap', 'station', IgnoreCase = $true)]
        [string]$RF_Role,

        [Parameter(ParameterSetName = 'Single')]
        [string]$RF_Channel,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 1000000)]
        [int]$RF_Channel_Frequency,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 10000)]
        [int]$RF_Channel_Width,

        [Parameter(ParameterSetName = 'Single')]
        [int]$TX_Power,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Primary_MAC_Address,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Owner,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Changelog_Message,

        [Parameter(ParameterSetName = 'Single')]
        [object[]]$Tags,

```

Leave all existing parameters (including `MTU`, `MAC_Address`, `MGMT_Only`, `LAG`, `Description`, `Mode`, `Untagged_VLAN`, `Tagged_VLANs`, and the Bulk-mode parameters) unchanged.

- [ ] **Step 4: Rebuild, run new tests — verify all pass**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*New-NBDCIMInterface new parameters*'" 2>&1 | tail -10
```

Expected: all 25 new tests pass.

- [ ] **Step 5: Run the full DCIM.Interfaces test file (regression check)**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Normal" 2>&1 | tail -3
```

Expected: baseline (from Task 1) + 25 = new count, zero failures.

- [ ] **Step 6: Restore artifact, stage, commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1 Tests/DCIM.Interfaces.Tests.ps1
git status --short
```

Expected `git status`: exactly these two files modified, nothing else.

```bash
git commit -m "$(cat <<'EOF'
feat: add 21 parameters to New-NBDCIMInterface (#394)

Adds full API coverage for: Label, Parent, Bridge, Speed, Duplex,
Mark_Connected, WWN, VDCS, POE_Mode, POE_Type, Vlan_Group, QinQ_SVLAN,
VRF, RF_Role, RF_Channel, RF_Channel_Frequency, RF_Channel_Width,
TX_Power, Primary_MAC_Address, Owner, Changelog_Message, Tags.

Type corrections vs. the originally-proposed PR #396:
- Vlan_Group, VRF, Owner, VDCS: switched from [string]/[Int64] to
  uint64 variants to match NetBox object ID conventions.
- Enum ValidateSets keep IgnoreCase=$true for consistency with the
  rest of the module.

Adds 25 integration tests covering positive paths for all 21 new
parameters plus ValidateSet negative tests on the four enum params
and the WWN pattern.

Reimplementation of community PR #396, closes part of #394.

Co-Authored-By: Matt Karel <mkarel@gmail.com>
EOF
)"
```

---

## Task 3: Set-NBDCIMInterface — add 21 parameters + 30 tests (Commit 2)

**Files:**
- Modify: `Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1`
- Modify: `Tests/DCIM.Interfaces.Tests.ps1` (append tests to `Context "Set-NBDCIMInterface"`)

- [ ] **Step 1: Append new tests to `Tests/DCIM.Interfaces.Tests.ps1`**

Find the closing `}` of `Context "Set-NBDCIMInterface"` (search for `Context "Set-NBDCIMInterface"`, then trace to its closing brace). Just before that `}`, append:

```powershell
Context "Set-NBDCIMInterface new parameters (#394)" {
    It "Should pass -Label in PATCH body" {
        $Result = Set-NBDCIMInterface -Id 42 -Label 'new-label'
        ($Result.Body | ConvertFrom-Json).label | Should -Be 'new-label'
    }

    It "Should pass -Parent as numeric ID in PATCH body" {
        $Result = Set-NBDCIMInterface -Id 42 -Parent 99
        ($Result.Body | ConvertFrom-Json).parent | Should -Be 99
    }

    It "Should send null when -Parent is explicitly null" {
        $Result = Set-NBDCIMInterface -Id 42 -Parent $null
        $Result.Body | Should -Match '"parent"\s*:\s*null'
    }

    It "Should pass -Bridge as numeric ID" {
        $Result = Set-NBDCIMInterface -Id 42 -Bridge 55
        ($Result.Body | ConvertFrom-Json).bridge | Should -Be 55
    }

    It "Should send null when -Bridge is explicitly null" {
        $Result = Set-NBDCIMInterface -Id 42 -Bridge $null
        $Result.Body | Should -Match '"bridge"\s*:\s*null'
    }

    It "Should pass -Speed in Kbps" {
        $Result = Set-NBDCIMInterface -Id 42 -Speed 10000000
        ($Result.Body | ConvertFrom-Json).speed | Should -Be 10000000
    }

    It "Should send null when -Speed is explicitly null" {
        $Result = Set-NBDCIMInterface -Id 42 -Speed $null
        $Result.Body | Should -Match '"speed"\s*:\s*null'
    }

    It "Should pass -Duplex with valid value 'auto'" {
        $Result = Set-NBDCIMInterface -Id 42 -Duplex 'auto'
        ($Result.Body | ConvertFrom-Json).duplex | Should -Be 'auto'
    }

    It "Should reject -Duplex with invalid value" {
        { Set-NBDCIMInterface -Id 42 -Duplex 'wrong' } | Should -Throw
    }

    It "Should pass -Mark_Connected as boolean" {
        $Result = Set-NBDCIMInterface -Id 42 -Mark_Connected $true
        ($Result.Body | ConvertFrom-Json).mark_connected | Should -Be $true
    }

    It "Should pass -WWN with valid format" {
        $Result = Set-NBDCIMInterface -Id 42 -WWN 'aa:bb:cc:dd:ee:ff:00:11'
        ($Result.Body | ConvertFrom-Json).wwn | Should -Be 'aa:bb:cc:dd:ee:ff:00:11'
    }

    It "Should pass -VDCS as array of integer IDs" {
        $Result = Set-NBDCIMInterface -Id 42 -VDCS 10, 20
        $body = $Result.Body | ConvertFrom-Json
        $body.vdcs | Should -Contain 10
        $body.vdcs | Should -Contain 20
    }

    It "Should pass -POE_Mode with valid value" {
        $Result = Set-NBDCIMInterface -Id 42 -POE_Mode 'pse'
        ($Result.Body | ConvertFrom-Json).poe_mode | Should -Be 'pse'
    }

    It "Should reject -POE_Mode with invalid value" {
        { Set-NBDCIMInterface -Id 42 -POE_Mode 'invalid' } | Should -Throw
    }

    It "Should pass -POE_Type with valid value" {
        $Result = Set-NBDCIMInterface -Id 42 -POE_Type 'type2-ieee802.3at'
        ($Result.Body | ConvertFrom-Json).poe_type | Should -Be 'type2-ieee802.3at'
    }

    It "Should pass -Vlan_Group as numeric ID" {
        $Result = Set-NBDCIMInterface -Id 42 -Vlan_Group 12
        ($Result.Body | ConvertFrom-Json).vlan_group | Should -Be 12
    }

    It "Should pass -QinQ_SVLAN as numeric ID" {
        $Result = Set-NBDCIMInterface -Id 42 -QinQ_SVLAN 300
        ($Result.Body | ConvertFrom-Json).qinq_svlan | Should -Be 300
    }

    It "Should send null when -QinQ_SVLAN is explicitly null" {
        $Result = Set-NBDCIMInterface -Id 42 -QinQ_SVLAN $null
        $Result.Body | Should -Match '"qinq_svlan"\s*:\s*null'
    }

    It "Should pass -VRF as numeric ID" {
        $Result = Set-NBDCIMInterface -Id 42 -VRF 8
        ($Result.Body | ConvertFrom-Json).vrf | Should -Be 8
    }

    It "Should pass -RF_Role with valid value" {
        $Result = Set-NBDCIMInterface -Id 42 -RF_Role 'station'
        ($Result.Body | ConvertFrom-Json).rf_role | Should -Be 'station'
    }

    It "Should reject -RF_Role with invalid value" {
        { Set-NBDCIMInterface -Id 42 -RF_Role 'not-a-role' } | Should -Throw
    }

    It "Should pass -RF_Channel as string" {
        $Result = Set-NBDCIMInterface -Id 42 -RF_Channel '5g-36-5180-20'
        ($Result.Body | ConvertFrom-Json).rf_channel | Should -Be '5g-36-5180-20'
    }

    It "Should pass -RF_Channel_Frequency as integer" {
        $Result = Set-NBDCIMInterface -Id 42 -RF_Channel_Frequency 5180
        ($Result.Body | ConvertFrom-Json).rf_channel_frequency | Should -Be 5180
    }

    It "Should send null when -RF_Channel_Frequency is explicitly null" {
        $Result = Set-NBDCIMInterface -Id 42 -RF_Channel_Frequency $null
        $Result.Body | Should -Match '"rf_channel_frequency"\s*:\s*null'
    }

    It "Should pass -RF_Channel_Width as integer" {
        $Result = Set-NBDCIMInterface -Id 42 -RF_Channel_Width 80
        ($Result.Body | ConvertFrom-Json).rf_channel_width | Should -Be 80
    }

    It "Should pass -TX_Power as integer" {
        $Result = Set-NBDCIMInterface -Id 42 -TX_Power 17
        ($Result.Body | ConvertFrom-Json).tx_power | Should -Be 17
    }

    It "Should pass -Primary_MAC_Address as numeric ID" {
        $Result = Set-NBDCIMInterface -Id 42 -Primary_MAC_Address 999
        ($Result.Body | ConvertFrom-Json).primary_mac_address | Should -Be 999
    }

    It "Should send null when -Primary_MAC_Address is explicitly null" {
        $Result = Set-NBDCIMInterface -Id 42 -Primary_MAC_Address $null
        $Result.Body | Should -Match '"primary_mac_address"\s*:\s*null'
    }

    It "Should pass -Owner as numeric ID" {
        $Result = Set-NBDCIMInterface -Id 42 -Owner 3
        ($Result.Body | ConvertFrom-Json).owner | Should -Be 3
    }

    It "Should pass -Changelog_Message as string" {
        $Result = Set-NBDCIMInterface -Id 42 -Changelog_Message 'Updated during maintenance'
        ($Result.Body | ConvertFrom-Json).changelog_message | Should -Be 'Updated during maintenance'
    }
}
```

- [ ] **Step 2: Build, run new tests — verify they fail**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*Set-NBDCIMInterface new parameters*'" 2>&1 | tail -30
```

Expected: ~30 new tests fail (parameters don't exist yet).

- [ ] **Step 3: Add the 21 new parameters to `Set-NBDCIMInterface.ps1`**

Open `Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1`. Add `.PARAMETER` blocks in the comment-based help (use the same text as from Task 2's help block above — copy it verbatim).

Then in the `param()` block, locate the `[string]$Type,` declaration. Immediately after it, insert:

```powershell
        [string]$Label,

        [Nullable[uint64]]$Parent,

        [Nullable[uint64]]$Bridge,

        [Nullable[uint64]]$Speed,

        [ValidateSet('full', 'half', 'auto', IgnoreCase = $true)]
        [string]$Duplex,

        [bool]$Mark_Connected,

        [ValidatePattern('^([0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$')]
        [string]$WWN,

        [uint64[]]$VDCS,

        [ValidateSet('pd', 'pse', IgnoreCase = $true)]
        [string]$POE_Mode,

        [ValidateSet('type1-ieee802.3af', 'type2-ieee802.3at', 'type3-ieee802.3bt', 'type4-ieee802.3bt', 'passive-24v-2pair', 'passive-24v-4pair', 'passive-48v-2pair', 'passive-48v-4pair', IgnoreCase = $true)]
        [string]$POE_Type,

        [uint64]$Vlan_Group,

        [Nullable[uint64]]$QinQ_SVLAN,

        [uint64]$VRF,

        [ValidateSet('ap', 'station', IgnoreCase = $true)]
        [string]$RF_Role,

        [string]$RF_Channel,

        [ValidateRange(1, 1000000)]
        [Nullable[int]]$RF_Channel_Frequency,

        [ValidateRange(1, 10000)]
        [Nullable[int]]$RF_Channel_Width,

        [Nullable[int]]$TX_Power,

        [Nullable[uint64]]$Primary_MAC_Address,

        [Nullable[uint64]]$Owner,

        [string]$Changelog_Message,

```

Do NOT touch existing parameters (MTU, MAC_Address, MGMT_Only, LAG, Description, Mode, Untagged_VLAN, Tagged_VLANs, Tags, Raw). `Tags` is already present.

- [ ] **Step 4: Rebuild, run new tests — verify all pass**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*Set-NBDCIMInterface new parameters*'" 2>&1 | tail -10
```

Expected: ~30 new tests pass.

- [ ] **Step 5: Full DCIM.Interfaces regression**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Normal" 2>&1 | tail -3
```

Expected: baseline (Task 1) + 25 (Task 2) + 30 (Task 3) = new count, zero failures.

- [ ] **Step 6: Restore artifact, stage, commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1 Tests/DCIM.Interfaces.Tests.ps1
git status --short
git commit -m "$(cat <<'EOF'
feat: add 21 parameters to Set-NBDCIMInterface (#394)

Mirror of the additions to New-NBDCIMInterface in the previous commit.
Numeric parameters that NetBox can clear to null on PATCH use the
[Nullable[T]] pattern (Parent, Bridge, Speed, QinQ_SVLAN, Primary_MAC_Address,
Owner, RF_Channel_Frequency, RF_Channel_Width, TX_Power) so users can
pass $null to clear the server-side value.

Enum string fields (Duplex, POE_Mode, POE_Type, RF_Role) do not support
explicit null-clearing in this change; see follow-up tracking issue.

Adds 30 integration tests: positive paths for all new parameters, ValidateSet
negatives on the three enum parameters, plus null-clearing verification on
the nine [Nullable[T]] numeric parameters (Parent, Bridge, Speed, QinQ_SVLAN,
Primary_MAC_Address, Owner, RF_Channel_Frequency, RF_Channel_Width, TX_Power).

Reimplementation of community PR #396, closes part of #394.

Co-Authored-By: Matt Karel <mkarel@gmail.com>
EOF
)"
```

---

## Task 4: Add `q-in-q` Mode value to New/Set-NBDCIMInterface (Commit 3)

**Files:**
- Modify: `Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1` — extend Mode ValidateSet + begin-block translation
- Modify: `Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1` — same
- Modify: `Tests/DCIM.Interfaces.Tests.ps1` — add 4 Mode tests
- Modify: `scripts/validateset-parity-exclusions.txt` — update comment on Mode exclusions

- [ ] **Step 1: Append Mode-specific tests to `Tests/DCIM.Interfaces.Tests.ps1`**

Add this new Context inside the existing `Describe "DCIM Interfaces Tests"` block (sibling to the other Contexts, e.g. at the end just before the `Describe`'s closing `}`):

```powershell
Context "DCIM Interface Mode — Q-in-Q support (#394)" {
    It "New-NBDCIMInterface: -Mode 'q-in-q' passes through verbatim" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Mode 'q-in-q'
        ($Result.Body | ConvertFrom-Json).mode | Should -Be 'q-in-q'
    }

    It "New-NBDCIMInterface: -Mode 'Q-in-Q' translates to 'q-in-q'" {
        $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Mode 'Q-in-Q'
        ($Result.Body | ConvertFrom-Json).mode | Should -Be 'q-in-q'
    }

    It "Set-NBDCIMInterface: -Mode 'q-in-q' passes through verbatim" {
        $Result = Set-NBDCIMInterface -Id 42 -Mode 'q-in-q'
        ($Result.Body | ConvertFrom-Json).mode | Should -Be 'q-in-q'
    }

    It "Set-NBDCIMInterface: -Mode 'Q-in-Q' translates to 'q-in-q'" {
        $Result = Set-NBDCIMInterface -Id 42 -Mode 'Q-in-Q'
        ($Result.Body | ConvertFrom-Json).mode | Should -Be 'q-in-q'
    }
}
```

- [ ] **Step 2: Build, run Mode tests — verify they fail**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*Q-in-Q support*'" 2>&1 | tail -15
```

Expected: 4 Mode tests fail (ValidateSet rejects `'q-in-q'` / `'Q-in-Q'`).

- [ ] **Step 3: Update `New-NBDCIMInterface.ps1` Mode parameter + begin block**

In `Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1`, find the `Mode` parameter's ValidateSet. It currently reads:

```powershell
        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('Access', 'Tagged', 'Tagged All', '100', '200', '300', IgnoreCase = $true)]
        [string]$Mode,
```

Change to:

```powershell
        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('Access', 'Tagged', 'Tagged All', 'Q-in-Q', 'q-in-q', '100', '200', '300', '400', IgnoreCase = $true)]
        [string]$Mode,
```

Then find the Mode-translation switch in the `begin {}` block. It currently reads:

```powershell
            if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
                $PSBoundParameters.Mode = switch ($Mode) {
                    'Access' { 'access' }
                    '100' { 'access' }
                    'Tagged' { 'tagged' }
                    '200' { 'tagged' }
                    'Tagged All' { 'tagged-all' }
                    '300' { 'tagged-all' }
                    default { $_ }
                }
            }
```

Replace with:

```powershell
            if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
                $PSBoundParameters.Mode = switch ($Mode) {
                    'Access' { 'access' }
                    '100' { 'access' }
                    'Tagged' { 'tagged' }
                    '200' { 'tagged' }
                    'Tagged All' { 'tagged-all' }
                    '300' { 'tagged-all' }
                    'Q-in-Q' { 'q-in-q' }
                    '400' { 'q-in-q' }
                    default { $_ }
                }
            }
```

- [ ] **Step 4: Update `Set-NBDCIMInterface.ps1` Mode parameter + begin block**

In `Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1`, find the Mode parameter:

```powershell
        [ValidateSet('Access', 'Tagged', 'Tagged All', '100', '200', '300', IgnoreCase = $true)]
        [string]$Mode,
```

Change to:

```powershell
        [ValidateSet('Access', 'Tagged', 'Tagged All', 'Q-in-Q', 'q-in-q', '100', '200', '300', '400', IgnoreCase = $true)]
        [string]$Mode,
```

Find its begin-block translation (the same `switch` pattern). Replace with the same extended mapping as Step 3 above (adds `'Q-in-Q' → 'q-in-q'` and `'400' → 'q-in-q'`).

- [ ] **Step 5: Update the exclusions file comment**

Open `scripts/validateset-parity-exclusions.txt`. Find the line that mentions `{New,Set}-NBDCIMInterface.ps1::Mode` (or similar referring to the Mode exclusion). Update the accompanying comment so it reads (keep the actual exclusion line itself unchanged — only the comment):

```
# Mode accepts legacy numeric/title-case values translated to API strings in begin {}.
# As of PR for #394, q-in-q (NetBox 4.2+) and its title-case variant Q-in-Q and
# legacy code '400' are also supported via the same translation layer.
```

If no pre-existing comment block exists around the Mode exclusion, add one above the exclusion line.

- [ ] **Step 6: Rebuild, run Mode tests**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*Q-in-Q support*'" 2>&1 | tail -10
```

Expected: all 4 Mode tests pass.

- [ ] **Step 7: Backward-compat regression — verify existing Mode tests still pass**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*Mode*'" 2>&1 | tail -20
```

Expected: all Mode-related tests pass (the pre-existing ones for 'Access'/'Tagged'/'Tagged All'/'100'/'200'/'300' plus the 4 new Q-in-Q tests).

- [ ] **Step 8: Full DCIM.Interfaces regression**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Normal" 2>&1 | tail -3
```

Expected: baseline + 25 + 30 + 4 = count, zero failures.

- [ ] **Step 9: Restore, stage, commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1 Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1 Tests/DCIM.Interfaces.Tests.ps1 scripts/validateset-parity-exclusions.txt
git status --short
git commit -m "$(cat <<'EOF'
fix: add Q-in-Q mode value to New/Set-NBDCIMInterface (#394)

NetBox 4.2+ introduced 'q-in-q' as a valid Interface Mode value (IEEE
802.1Q-in-Q tunneling). Adds 'q-in-q' plus the PowerShell title-case
variant 'Q-in-Q' and the legacy numeric code '400' to the Mode
ValidateSet on both New- and Set-NBDCIMInterface, with translations
from title-case/legacy codes to the canonical 'q-in-q' string.

Preserves full backward compatibility: existing values ('Access',
'Tagged', 'Tagged All', '100', '200', '300') continue translating to
('access', 'tagged', 'tagged-all') exactly as before.

Updates scripts/validateset-parity-exclusions.txt comment to reflect
the expanded translation layer.

Adds 4 tests covering both pass-through and title-case translation on
both New- and Set-.
EOF
)"
```

---

## Task 5: Sync `Get-NBDCIMInterface -Type` ValidateSet with New/Set (Commit 4, closes #392 item 2)

**Files:**
- Modify: `Functions/DCIM/Interfaces/Get-NBDCIMInterface.ps1` — replace the shorter -Type ValidateSet with the full 216-type list from New/Set
- Modify: `Tests/DCIM.Interfaces.Tests.ps1` — add 3 probe tests

- [ ] **Step 1: Append new tests to `Tests/DCIM.Interfaces.Tests.ps1`**

Find `Context "Get-NBDCIMInterface"`. Before its closing `}`, append:

```powershell
Context "Get-NBDCIMInterface -Type drift fix (#392 item 2)" {
    It "Accepts the newly-added 800gbase-x-qsfpdd type" {
        $Result = Get-NBDCIMInterface -Type '800gbase-x-qsfpdd'
        $Result.Uri | Should -Match 'type=800gbase-x-qsfpdd'
    }

    It "Accepts the newly-added 1.6tbase-kr8 type" {
        $Result = Get-NBDCIMInterface -Type '1.6tbase-kr8'
        $Result.Uri | Should -Match 'type=1\.6tbase-kr8'
    }

    It "Accepts the newly-added 200gbase-sr4 type" {
        $Result = Get-NBDCIMInterface -Type '200gbase-sr4'
        $Result.Uri | Should -Match 'type=200gbase-sr4'
    }
}
```

- [ ] **Step 2: Build, run new tests — verify they fail**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*Type drift fix*'" 2>&1 | tail -15
```

Expected: 3 tests fail with ValidateSet rejection on the newly-added type names.

- [ ] **Step 3: Replace the `-Type` ValidateSet in `Get-NBDCIMInterface.ps1`**

Open `Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1` and copy the exact contents between the parentheses of the `[ValidateSet(...)]` on the `$Type` parameter (around line 105). This is the full 216-type list.

Open `Functions/DCIM/Interfaces/Get-NBDCIMInterface.ps1`. Find the `-Type` parameter's current `[ValidateSet(...)]`. Replace its contents with the full list from New-NBDCIMInterface, preserving the existing `IgnoreCase = $true` attribute at the end.

Verify by grep:

```bash
grep -c "ieee802.11be" Functions/DCIM/Interfaces/Get-NBDCIMInterface.ps1
```

Expected: `1` (the new ValidateSet contains it). Before your change it would return `0`.

- [ ] **Step 4: Rebuild, run new tests — verify all pass**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Detailed -FullNameFilter '*Type drift fix*'" 2>&1 | tail -10
```

Expected: 3 new tests pass.

- [ ] **Step 5: Verify the parity tool now reports 16 findings instead of 17**

```bash
pwsh -NoProfile -File ./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.7 2>&1 | grep -E "(Found .* discrepancies|Get-NBDCIMInterface.ps1 :: -Type)"
```

Expected: the top line reports 16 (down from 17), and the `Get-NBDCIMInterface.ps1 :: -Type` line is absent from the output.

- [ ] **Step 6: Full regression**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Interfaces.Tests.ps1 -Output Normal" 2>&1 | tail -3
```

Expected: baseline + 25 + 30 + 4 + 3 = final count, zero failures.

- [ ] **Step 7: Restore, stage, commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/DCIM/Interfaces/Get-NBDCIMInterface.ps1 Tests/DCIM.Interfaces.Tests.ps1
git status --short
git commit -m "$(cat <<'EOF'
fix: sync Get-NBDCIMInterface -Type ValidateSet with New/Set (#392 item 2)

The -Type ValidateSet on Get-NBDCIMInterface was left behind during
PR #369's expansion of New/Set to 208 types in v4.5.4.0 and again
during PR #381's addition of 1.6TE types in v4.5.6.0. Users could
not filter existing devices by any of the 104 newer interface types,
including all 100/200/400/800GBASE variants, 1.6TbE variants,
InfiniBand NDR/XDR, and SONET/IEEE802.11be.

Replaces the stale -Type ValidateSet with the full 216-type list
from New-/Set-NBDCIMInterface. Strictly expansive change — every
previously-accepted value still validates.

Closes #392 item 2. Adds 3 probe tests exercising a sample of the
newly-valid types (800gbase-x-qsfpdd, 1.6tbase-kr8, 200gbase-sr4).
EOF
)"
```

---

## Task 6: Full regression + PSScriptAnalyzer + parity tool verification

**Files:** none (read-only)

- [ ] **Step 1: Full Pester unit test suite**

```bash
pwsh -NoProfile -File ./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/ -ExcludeTagFilter Integration,Live,Scenario -Output Normal" 2>&1 | tail -3
```

Expected pass count: 2192 baseline (from PR-1 merge to dev) + 62 new = 2254. Zero failures. 11 skipped is expected (Setup-tests needing credentials).

- [ ] **Step 2: PSScriptAnalyzer on changed production files**

```bash
pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path Functions/DCIM/Interfaces/New-NBDCIMInterface.ps1 -Severity Error,Warning; Invoke-ScriptAnalyzer -Path Functions/DCIM/Interfaces/Set-NBDCIMInterface.ps1 -Severity Error,Warning; Invoke-ScriptAnalyzer -Path Functions/DCIM/Interfaces/Get-NBDCIMInterface.ps1 -Severity Error,Warning" 2>&1 | tail -10
```

Expected: no output (zero findings). Empty result = clean.

- [ ] **Step 3: Parity tool confirms drift reduction**

```bash
pwsh -NoProfile -File ./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.7 -OutputFormat Json 2>&1 | tail -3
```

Read the final summary line: findings count should now be 16 (was 17). The `Get-NBDCIMInterface.ps1 :: -Type` line should be absent.

- [ ] **Step 4: Confirm branch state**

```bash
git status --short
git log --oneline origin/dev..HEAD
```

Expected commits on the branch (top to bottom, newest first):
1. `fix: sync Get-NBDCIMInterface -Type ValidateSet with New/Set (#392 item 2)`
2. `fix: add Q-in-Q mode value to New/Set-NBDCIMInterface (#394)`
3. `feat: add 21 parameters to Set-NBDCIMInterface (#394)`
4. `feat: add 21 parameters to New-NBDCIMInterface (#394)`
5. `docs: design spec for DCIM Interface parameters (#394) + Type drift fix (#392 item 2)`

`git status` should be clean (no unstaged changes).

---

## Task 7: Push + open PR

**Files:** none (GitHub)

- [ ] **Step 1: Push the branch**

```bash
git push -u origin feat/394-interface-parameters 2>&1 | tail -5
```

Expected: `* [new branch]   feat/394-interface-parameters -> feat/394-interface-parameters`.

- [ ] **Step 2: Create the pull request targeting `dev`**

```bash
gh pr create --base dev --title "feat: 21 Interface parameters (#394) + Get-Type drift fix (#392 item 2)" --body "$(cat <<'EOF'
## Summary

Reimplementation of community PR #396 by @mkarel with full credit, plus a bundled fix for issue #392 item 2.

- Adds 21 parameters to `New-NBDCIMInterface` and `Set-NBDCIMInterface` (full NetBox Interface API coverage).
- Adds `q-in-q` Mode value (NetBox 4.2+) in a backward-compatible way.
- Synchronizes `Get-NBDCIMInterface -Type` ValidateSet with New/Set (closes #392 item 2 — 104 previously-missing interface types now filterable).

## Design

See [`docs/superpowers/specs/2026-04-17-interface-parameters-design.md`](docs/superpowers/specs/2026-04-17-interface-parameters-design.md) for the complete design spec.

## Credit

Matt Karel (@mkarel) proposed the feature in #394 and submitted the initial implementation in PR #396 (closed and reimplemented here per the project's external PR pattern). The two `feat:` commits carry `Co-Authored-By: Matt Karel <mkarel@gmail.com>` trailers.

Release notes will read: *"21 new interface parameters on New/Set-NBDCIMInterface — proposed and initial implementation by @mkarel (#394, original PR #396)."*

## Type corrections vs. PR #396

- `Vlan_Group`, `VRF`: `[string]` → `[uint64]` (NetBox API expects object IDs)
- `Owner`: `[Int64]` → `[uint64]` (consistent with all NetBox ID params)
- `VDCS`: `[string[]]` → `[uint64[]]` (M2M relation expects IDs)
- Enum `IgnoreCase = $false` → `$true` (consistent with the rest of the module)

## Mode parameter — conservative Q-in-Q addition

Adds `'q-in-q'` (canonical), `'Q-in-Q'` (title-case variant), and `'400'` (legacy numeric) to the ValidateSet. All three translate to `'q-in-q'` in the begin block. Preserves full backward compatibility with existing `'Access'`/`'Tagged'`/`'Tagged All'`/`'100'`/`'200'`/`'300'` behavior. `IgnoreCase = $true` retained.

## Null-clearing on Set-

Numeric-ID parameters that NetBox can clear via `PATCH` with `null` use `[Nullable[T]]`: `Parent`, `Bridge`, `Speed`, `QinQ_SVLAN`, `Primary_MAC_Address`, `Owner`, `RF_Channel_Frequency`, `RF_Channel_Width`, `TX_Power`.

Enum string fields (`Duplex`, `POE_Mode`, `POE_Type`, `RF_Role`, `Mode`) do NOT support null-clearing in this PR — deferred to a separate tracking issue to be opened post-merge. Callers needing to clear these fields in the meantime can use direct REST or bulk update.

## Test plan

- [x] 25 integration tests on `Context "New-NBDCIMInterface new parameters (#394)"`
- [x] 30 integration tests on `Context "Set-NBDCIMInterface new parameters (#394)"` (including null-clearing)
- [x] 4 tests on `Context "DCIM Interface Mode — Q-in-Q support (#394)"`
- [x] 3 tests on `Context "Get-NBDCIMInterface -Type drift fix (#392 item 2)"`
- [x] Full unit regression (excluding Integration/Live/Scenario): 2192 baseline + 62 = 2254 passed / 0 failed
- [x] PSScriptAnalyzer on 3 changed production files: 0 findings
- [x] `scripts/Verify-ValidateSetParity.ps1` drift count 17 → 16 (item 2 of #392 closed)
- [ ] CI passes on PS 5.1 (Windows) and PS 7 (Linux/macOS/Windows)
- [ ] Manual smoke test against a live NetBox: `New-NBDCIMInterface -POE_Mode 'pse' -POE_Type 'type3-ieee802.3bt' -Speed 10000000` creates an interface with all three fields applied
- [ ] Manual smoke test: `Set-NBDCIMInterface -Parent $null` on an interface with a parent clears the parent reference

## Closes

- #392 (item 2 — `Get-NBDCIMInterface -Type` drift)

## Relates to

- #394 (feature request — stays open as tracker; will close on merge via reference in this PR's description)
- #396 (closed; this PR is the reimplementation)
EOF
)" 2>&1