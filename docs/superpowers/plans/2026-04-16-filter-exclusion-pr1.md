# Brief/Fields/Omit Mutual Exclusion — PR-1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `AssertNBMutualExclusiveParam` helper and apply it to 3 pilot Get functions, proving the pattern works before PR-2 rolls out to the remaining 121 functions.

**Architecture:** One internal helper (`Functions/Helpers/AssertNBMutualExclusiveParam.ps1`) throws a `ParameterBindingException` when ≥2 of a named parameter list are supplied together. Each Get function calls it once at the top of `process { }`. Special case: `Get-NBDCIMDevice`'s `IncludeConfigContext`-driven auto-omit is guarded so it only fires when neither `Brief` nor `Fields` is specified.

**Tech Stack:** PowerShell 5.1+ / 7, Pester v5 tests, module built via `./deploy.ps1 -Environment dev -SkipVersion`, branch `fix/silent-filter-combination`.

**Spec reference:** `docs/superpowers/specs/2026-04-16-filter-exclusion-design.md`

---

## Task 1: Establish baseline

**Files:**
- Read-only: `PowerNetbox.psd1`, `Tests/**`

- [ ] **Step 1: Confirm current branch**

```bash
cd /Users/elvis/Developer/PowerNetbox-project/PowerNetbox
git rev-parse --abbrev-ref HEAD
```

Expected output: `fix/silent-filter-combination`

If you are on another branch, stop and switch: `git checkout fix/silent-filter-combination`. Do not proceed if HEAD is on `dev` or `main`.

- [ ] **Step 2: Build the module**

```bash
./deploy.ps1 -Environment dev -SkipVersion
```

Expected output: last line mentions successful build. No errors. This populates `PowerNetbox/PowerNetbox/PowerNetbox.psd1` (the gitignored build artifact).

- [ ] **Step 3: Run the existing Helpers tests (sanity check)**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Helpers.Tests.ps1 -Output Detailed"
```

Expected: all existing tests pass. Record the passing count — you'll add to it.

- [ ] **Step 4: Run the existing Devices/IPAM/VPN tests**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1, ./Tests/IPAM.Tests.ps1, ./Tests/VPN.Tests.ps1 -Output Detailed"
```

Expected: all tests pass. Record the passing count.

- [ ] **Step 5: Restore the build artifact before starting**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null; git status --short
```

Expected: clean working tree (other than untracked files). `deploy.ps1` sometimes stamps the source `PowerNetbox.psd1` with a fresh date — this reset avoids committing build noise later.

---

## Task 2: Add `AssertNBMutualExclusiveParam` helper (TDD)

**Files:**
- Create: `Functions/Helpers/AssertNBMutualExclusiveParam.ps1`
- Modify: `Tests/Helpers.Tests.ps1` (append new `Context`)

- [ ] **Step 1: Write the failing tests**

Open `Tests/Helpers.Tests.ps1`. Append this new `Context` block inside the existing top-level `Describe "Helpers tests"` block, just before its closing `}`:

```powershell
Context "AssertNBMutualExclusiveParam" {
    It "Does not throw when zero parameters from the list are bound" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $bound = @{}
            { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                Should -Not -Throw
        }
    }

    It "Does not throw when exactly one parameter from the list is bound" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $bound = @{ Brief = $true }
            { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                Should -Not -Throw
        }
    }

    It "Throws ParameterBindingException when two parameters are bound" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $bound = @{ Brief = $true; Fields = @('id', 'name') }
            { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
        }
    }

    It "Throws with a message naming all conflicting parameters when three are bound" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $bound = @{ Brief = $true; Fields = @('id'); Omit = @('x') }
            try {
                AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit'
                throw "Expected an exception but none was thrown"
            } catch [System.Management.Automation.ParameterBindingException] {
                $_.Exception.Message | Should -Match '-Brief'
                $_.Exception.Message | Should -Match '-Fields'
                $_.Exception.Message | Should -Match '-Omit'
                $_.Exception.Message | Should -Match 'mutually exclusive'
            }
        }
    }

    It "Appends HelpHint to the exception message when supplied" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $bound = @{ Brief = $true; Fields = @('id') }
            try {
                AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' -HelpHint 'See Get-Help for alternatives.'
                throw "Expected an exception but none was thrown"
            } catch [System.Management.Automation.ParameterBindingException] {
                $_.Exception.Message | Should -Match 'See Get-Help for alternatives\.'
            }
        }
    }

    It "Rejects calls with fewer than 2 parameter names via ValidateCount" {
        InModuleScope -ModuleName 'PowerNetbox' {
            { AssertNBMutualExclusiveParam -BoundParameters @{} -Parameters 'Brief' } |
                Should -Throw
        }
    }

    It "Treats parameter names case-sensitively (matching PSBoundParameters semantics)" {
        InModuleScope -ModuleName 'PowerNetbox' {
            # PSBoundParameters keys are case-insensitive in practice, but we match
            # whatever the caller provides. Verify that an exact-match pair triggers
            # the throw, and that only-lower-case-key also triggers (PSBoundParameters
            # is case-insensitive).
            $bound = @{ brief = $true; fields = @('id') }
            { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'brief', 'fields' } |
                Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
        }
    }

    It "Accepts a generic Dictionary as BoundParameters" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $bound = [System.Collections.Generic.Dictionary[string, object]]::new()
            $bound['Brief'] = $true
            $bound['Fields'] = @('id')
            { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
        }
    }

    It "Does not throw for empty or null BoundParameters" {
        InModuleScope -ModuleName 'PowerNetbox' {
            { AssertNBMutualExclusiveParam -BoundParameters @{} -Parameters 'Brief', 'Fields', 'Omit' } |
                Should -Not -Throw
        }
    }

    It "Ignores parameters outside the checked list" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $bound = @{ Brief = $true; Limit = 10; Offset = 100 }
            { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                Should -Not -Throw
        }
    }
}
```

- [ ] **Step 2: Build, then run the new tests — verify they fail**

```bash
./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Helpers.Tests.ps1 -Output Detailed -FullNameFilter '*AssertNBMutualExclusiveParam*'"
```

Expected: **all 10 new tests fail** with error messages like "The term 'AssertNBMutualExclusiveParam' is not recognized...". This confirms the tests are wired correctly before the implementation exists.

- [ ] **Step 3: Create the helper file**

Create `Functions/Helpers/AssertNBMutualExclusiveParam.ps1` with this content:

```powershell
function AssertNBMutualExclusiveParam {
    <#
    .SYNOPSIS
        Throws when two or more of the named parameters are present in a bound-parameters dictionary.

    .DESCRIPTION
        Internal helper used to enforce mutual exclusion between cmdlet parameters
        at runtime. Throws a terminating ParameterBindingException that names the
        conflicting parameters.

    .PARAMETER BoundParameters
        The $PSBoundParameters dictionary from the calling cmdlet, or any
        IDictionary that maps parameter names to values.

    .PARAMETER Parameters
        The list of parameter names that are mutually exclusive. At least two
        must be provided; typically 2-5 in practice.

    .PARAMETER HelpHint
        Optional text appended to the exception message (e.g. a pointer to docs).

    .EXAMPLE
        AssertNBMutualExclusiveParam -BoundParameters $PSBoundParameters -Parameters 'Brief','Fields','Omit'
    #>
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

- [ ] **Step 4: Rebuild the module**

```bash
./deploy.ps1 -Environment dev -SkipVersion
```

Expected: the build output list includes `Functions/Helpers/AssertNBMutualExclusiveParam.ps1` (or the helper count increases by 1).

- [ ] **Step 5: Run the tests — verify they pass**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Helpers.Tests.ps1 -Output Detailed -FullNameFilter '*AssertNBMutualExclusiveParam*'"
```

Expected: **all 10 new tests pass**.

- [ ] **Step 6: Run the full Helpers test suite (regression check)**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/Helpers.Tests.ps1 -Output Detailed"
```

Expected: all tests pass, including the pre-existing ones from Task 1 Step 3. Zero failures.

- [ ] **Step 7: Restore build artifact, stage, commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/Helpers/AssertNBMutualExclusiveParam.ps1 Tests/Helpers.Tests.ps1
git status --short
```

Expected `git status` output: only the two files added, no unexpected modifications.

```bash
git commit -m "$(cat <<'EOF'
feat: add AssertNBMutualExclusiveParam helper

Internal helper that throws ParameterBindingException when two or
more of a named parameter list are present in a bound-parameters
dictionary. Consumed by Get functions to enforce that -Brief,
-Fields, and -Omit are mutually exclusive (see spec).

Adds 10 unit tests in Tests/Helpers.Tests.ps1.
EOF
)"
```

---

## Task 3: Apply assertion to `Get-NBIPAMAddress` (standard pilot)

**Files:**
- Modify: `Functions/IPAM/Address/Get-NBIPAMAddress.ps1:121-123` (insert one call)
- Modify: `Tests/IPAM.Tests.ps1` (append 4 tests to `Context "Get-NBIPAMAddress"`)

- [ ] **Step 1: Write the failing tests**

Open `Tests/IPAM.Tests.ps1`. Find the `Context "Get-NBIPAMAddress" {` block (line 44). Inside that block, before its closing `}`, append:

```powershell
Context "Brief/Fields/Omit mutual exclusion" {
    It "Throws when -Brief and -Fields are both specified" {
        { Get-NBIPAMAddress -Brief -Fields 'id' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Throws when -Brief and -Omit are both specified" {
        { Get-NBIPAMAddress -Brief -Omit 'comments' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Throws when -Fields and -Omit are both specified" {
        { Get-NBIPAMAddress -Fields 'id' -Omit 'comments' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Does not throw when -Brief is specified alone (control)" {
        $Result = Get-NBIPAMAddress -Brief
        $Result.Method | Should -Be 'GET'
        $Result.Uri | Should -Match 'brief=True'
    }
}
```

- [ ] **Step 2: Build, run tests — verify the three throw-tests fail**

```bash
./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/IPAM.Tests.ps1 -Output Detailed -FullNameFilter '*Brief/Fields/Omit mutual exclusion*'"
```

Expected: the 3 throw-tests fail (the function accepts combinations silently today); the 1 control test passes.

- [ ] **Step 3: Add the assertion call to `Get-NBIPAMAddress`**

Open `Functions/IPAM/Address/Get-NBIPAMAddress.ps1`. Locate the `process {` block at line 121. Change it from:

```powershell
    process {
        Write-Verbose "Retrieving IPAM Address"
        switch ($PSCmdlet.ParameterSetName) {
```

…to:

```powershell
    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'

        Write-Verbose "Retrieving IPAM Address"
        switch ($PSCmdlet.ParameterSetName) {
```

- [ ] **Step 4: Rebuild the module**

```bash
./deploy.ps1 -Environment dev -SkipVersion
```

- [ ] **Step 5: Run tests — verify all 4 pass**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/IPAM.Tests.ps1 -Output Detailed -FullNameFilter '*Brief/Fields/Omit mutual exclusion*'"
```

Expected: all 4 new tests pass.

- [ ] **Step 6: Run the full IPAM test file (regression check)**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/IPAM.Tests.ps1 -Output Detailed"
```

Expected: zero failures. Pre-existing IPAM tests continue to pass.

- [ ] **Step 7: Restore build artifact, stage, commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/IPAM/Address/Get-NBIPAMAddress.ps1 Tests/IPAM.Tests.ps1
git status --short
git commit -m "$(cat <<'EOF'
feat: enforce Brief/Fields/Omit mutual exclusion on Get-NBIPAMAddress

First standard-pattern pilot for the helper introduced in the
previous commit. Adds 4 integration tests.
EOF
)"
```

---

## Task 4: Apply assertion to `Get-NBVPNTunnel` (standard pilot)

**Files:**
- Modify: `Functions/VPN/Tunnel/Get-NBVPNTunnel.ps1:66-68`
- Modify: `Tests/VPN.Tests.ps1` (append 4 tests to `Context "Get-NBVPNTunnel"`)

- [ ] **Step 1: Write the failing tests**

Open `Tests/VPN.Tests.ps1`. Find the `Context "Get-NBVPNTunnel" {` block (line 41). Inside that block, before its closing `}`, append:

```powershell
Context "Brief/Fields/Omit mutual exclusion" {
    It "Throws when -Brief and -Fields are both specified" {
        { Get-NBVPNTunnel -Brief -Fields 'id' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Throws when -Brief and -Omit are both specified" {
        { Get-NBVPNTunnel -Brief -Omit 'comments' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Throws when -Fields and -Omit are both specified" {
        { Get-NBVPNTunnel -Fields 'id' -Omit 'comments' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Does not throw when -Brief is specified alone (control)" {
        $Result = Get-NBVPNTunnel -Brief
        $Result.Method | Should -Be 'GET'
        $Result.Uri | Should -Match 'brief=True'
    }
}
```

- [ ] **Step 2: Build, run tests — verify the three throw-tests fail**

```bash
./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1 -Output Detailed -FullNameFilter '*Brief/Fields/Omit mutual exclusion*'"
```

Expected: 3 fail, 1 pass.

- [ ] **Step 3: Add the assertion call to `Get-NBVPNTunnel`**

Open `Functions/VPN/Tunnel/Get-NBVPNTunnel.ps1`. Locate the `process {` block at line 66. Change from:

```powershell
    process {
        Write-Verbose "Retrieving VPN Tunnel"
        switch ($PSCmdlet.ParameterSetName) {
```

…to:

```powershell
    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'

        Write-Verbose "Retrieving VPN Tunnel"
        switch ($PSCmdlet.ParameterSetName) {
```

- [ ] **Step 4: Rebuild and run tests — verify all 4 pass**

```bash
./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1 -Output Detailed -FullNameFilter '*Brief/Fields/Omit mutual exclusion*'"
```

Expected: all 4 new tests pass.

- [ ] **Step 5: Run the full VPN test file (regression check)**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/VPN.Tests.ps1 -Output Detailed"
```

Expected: zero failures.

- [ ] **Step 6: Restore build artifact, stage, commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/VPN/Tunnel/Get-NBVPNTunnel.ps1 Tests/VPN.Tests.ps1
git status --short
git commit -m "$(cat <<'EOF'
feat: enforce Brief/Fields/Omit mutual exclusion on Get-NBVPNTunnel

Second standard-pattern pilot. Adds 4 integration tests.
EOF
)"
```

---

## Task 5: Apply assertion to `Get-NBDCIMDevice` (special case with `IncludeConfigContext`)

**Files:**
- Modify: `Functions/DCIM/Devices/Get-NBDCIMDevice.ps1:193-203` (insert call, guard auto-omit)
- Modify: `Tests/DCIM.Devices.Tests.ps1` (append mutex-exclusion and special-case tests to `Context "Get-NBDCIMDevice"`)

- [ ] **Step 1: Write the failing tests**

Open `Tests/DCIM.Devices.Tests.ps1`. Find the `Context "Get-NBDCIMDevice" {` block (line 39). Inside that block, before its closing `}`, append:

```powershell
Context "Brief/Fields/Omit mutual exclusion" {
    It "Throws when -Brief and -Fields are both specified" {
        { Get-NBDCIMDevice -Brief -Fields 'id' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Throws when -Brief and -Omit are both specified" {
        { Get-NBDCIMDevice -Brief -Omit 'comments' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Throws when -Fields and -Omit are both specified" {
        { Get-NBDCIMDevice -Fields 'id' -Omit 'comments' } |
            Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
    }

    It "Does not throw when -Brief is specified alone (control)" {
        $Result = Get-NBDCIMDevice -Brief
        $Result.Method | Should -Be 'GET'
        $Result.Uri | Should -Match 'brief=True'
    }
}

Context "Brief/Fields/Omit interaction with IncludeConfigContext" {
    It "With -Brief: URI contains brief=True and no config_context omit" {
        $Result = Get-NBDCIMDevice -Brief
        $Result.Uri | Should -Match 'brief=True'
        $Result.Uri | Should -Not -Match 'omit=config_context'
    }

    It "With -Fields: URI contains the fields parameter and no config_context omit" {
        $Result = Get-NBDCIMDevice -Fields 'id', 'name'
        # Match 'fields=' separately from each value name — commas between
        # values may be URL-encoded as %2C on some platforms but the field
        # names themselves will appear literally.
        $Result.Uri | Should -Match 'fields='
        $Result.Uri | Should -Match 'id'
        $Result.Uri | Should -Match 'name'
        $Result.Uri | Should -Not -Match 'omit=config_context'
    }

    It "With -Omit: URI contains the user's omit value merged with config_context" {
        $Result = Get-NBDCIMDevice -Omit 'comments'
        $Result.Uri | Should -Match 'omit='
        $Result.Uri | Should -Match 'comments'
        $Result.Uri | Should -Match 'config_context'
    }

    It "With -IncludeConfigContext -Brief: URI contains brief=True only (IncludeConfigContext silently ignored)" {
        $Result = Get-NBDCIMDevice -IncludeConfigContext -Brief
        $Result.Uri | Should -Match 'brief=True'
        $Result.Uri | Should -Not -Match 'config_context'
    }

    It "With no projection flags: URI contains the default config_context auto-omit" {
        $Result = Get-NBDCIMDevice
        $Result.Uri | Should -Match 'omit=config_context'
    }
}
```

- [ ] **Step 2: Build, run tests — verify the mutex tests + at least two special-case tests fail**

```bash
./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1 -Output Detailed -FullNameFilter '*Brief/Fields/Omit*'"
```

Expected failures:
- All 3 throw-tests fail (current function accepts combinations silently).
- "With -Brief: URI contains brief=True and no config_context omit" fails (current code always appends `omit=config_context` unless `-IncludeConfigContext`, so the URI contains both).
- "With -Fields: URI contains fields= and no config_context omit" fails for the same reason.

Expected passes (before the fix):
- The `-Omit 'comments'` case (merge behavior already correct).
- The `-IncludeConfigContext -Brief` case (already produces `brief=True` with no config_context, because `IncludeConfigContext` suppresses the auto-omit).
- The no-flags case (`omit=config_context` already present).

Record exactly which tests fail — the fix should turn these from FAIL to PASS without affecting the already-passing ones.

- [ ] **Step 3: Edit `Get-NBDCIMDevice.ps1`**

Open `Functions/DCIM/Devices/Get-NBDCIMDevice.ps1`. Locate the `process {` block at line 193. Currently:

```powershell
    process {
        Write-Verbose "Retrieving DCIM Device"

        # Build omit list: add config_context unless explicitly included
        $omitFields = @()
        if ($PSBoundParameters.ContainsKey('Omit')) {
            $omitFields += $Omit
        }
        if (-not $IncludeConfigContext) {
            $omitFields += 'config_context'
        }
```

Replace that block with:

```powershell
    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'

        Write-Verbose "Retrieving DCIM Device"

        # Auto-omit config_context only when the user has not otherwise
        # restricted the projection. -Brief returns a minimal representation
        # (config_context is never included). -Fields explicitly selects the
        # returned shape, so the user owns that choice.
        $inProjectionMode = $PSBoundParameters.ContainsKey('Brief') -or
                            $PSBoundParameters.ContainsKey('Fields')

        $omitFields = @()
        if ($PSBoundParameters.ContainsKey('Omit')) {
            $omitFields += $Omit
        }
        if (-not $IncludeConfigContext -and -not $inProjectionMode) {
            $omitFields += 'config_context'
        }
```

Leave the rest of the function body (the `switch ($PSCmdlet.ParameterSetName)` block and below) unchanged.

- [ ] **Step 4: Rebuild and run the new tests**

```bash
./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1 -Output Detailed -FullNameFilter '*Brief/Fields/Omit*'"
```

Expected: all 9 new tests pass (4 mutex + 5 interaction).

- [ ] **Step 5: Run the full DCIM.Devices test file (regression check)**

```bash
pwsh -NoProfile -Command "Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1 -Output Detailed"
```

Expected: zero failures. Pre-existing tests (e.g., "Should request the default number of devices" which checks for `omit=config_context`) continue to pass because the default path is unchanged.

- [ ] **Step 6: Restore build artifact, stage, commit**

```bash
git checkout -- PowerNetbox.psd1 2>/dev/null
git add Functions/DCIM/Devices/Get-NBDCIMDevice.ps1 Tests/DCIM.Devices.Tests.ps1
git status --short
git commit -m "$(cat <<'EOF'
feat: enforce Brief/Fields/Omit mutual exclusion on Get-NBDCIMDevice

Third pilot, covering the IncludeConfigContext special case. The
auto-omit of config_context is now guarded: it only fires when the
user has not specified -Brief or -Fields (in which case the server
already controls the response shape).

Adds 4 mutex-exclusion tests + 5 interaction tests covering the full
behavior matrix from the spec.
EOF
)"
```

---

## Task 6: Full regression check

**Files:** none (read-only)

- [ ] **Step 1: Run the full Pester unit test suite**

```bash
./deploy.ps1 -Environment dev -SkipVersion
pwsh -NoProfile -Command "Invoke-Pester ./Tests/ -ExcludeTagFilter Integration -Output Detailed"
```

Expected output: pass count equals the baseline from Task 1 plus the new tests added in Tasks 2–5 (10 + 4 + 4 + 9 = 27 new tests). Zero failures.

- [ ] **Step 2: Run PSScriptAnalyzer (catches lint issues before CI does)**

```bash
pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning -ExcludeRule PSUseDeclaredVarsMoreThanAssignments"
```

Expected: zero new findings on the files changed in this branch. Ignore pre-existing findings on files you didn't touch.

- [ ] **Step 3: Confirm build artifact is not staged**

```bash
git status --short
git log --oneline origin/dev..HEAD
```

Expected commits on the branch (top to bottom, newest first):
1. `feat: enforce Brief/Fields/Omit mutual exclusion on Get-NBDCIMDevice`
2. `feat: enforce Brief/Fields/Omit mutual exclusion on Get-NBVPNTunnel`
3. `feat: enforce Brief/Fields/Omit mutual exclusion on Get-NBIPAMAddress`
4. `feat: add AssertNBMutualExclusiveParam helper`
5. `docs: design spec for Brief/Fields/Omit mutual exclusion`

`git status` should be clean (no unstaged changes).

- [ ] **Step 4: Push the branch**

```bash
git push -u origin fix/silent-filter-combination
```

---

## Task 7: Open PR-1

**Files:** none (GitHub)

- [ ] **Step 1: Create the pull request**

```bash
gh pr create --base dev --title "fix: enforce mutual exclusion between -Brief, -Fields, -Omit (PR-1: helper + 3 pilots)" --body "$(cat <<'EOF'
## Summary

Implements PR-1 of the two-phase rollout described in `docs/superpowers/specs/2026-04-16-filter-exclusion-design.md`.

- Adds internal helper `AssertNBMutualExclusiveParam` (`Functions/Helpers/`) with 10 unit tests.
- Applies it to 3 pilot Get functions: `Get-NBDCIMDevice`, `Get-NBIPAMAddress`, `Get-NBVPNTunnel`.
- Guards the `config_context` auto-omit in `Get-NBDCIMDevice` so it only fires when the user hasn't otherwise restricted the projection (via `-Brief` or `-Fields`).
- Adds 17 integration + interaction tests.

## Why

Today, supplying `-Brief` with `-Fields` or `-Omit` silently passes all three to Netbox, which applies undefined precedence (brief typically wins). Scripts that combine these flags get the result of one and ignore the others — a silent-surprise class of bug that Gemini has flagged three times in code review.

This PR introduces the mechanism and validates it on three representative functions. PR-2 (tracked separately) will roll it out to the remaining 121 Get functions and add a CI auditor.

## Test plan

- [ ] CI passes on all platforms (PS 5.1, PS 7)
- [ ] PSScriptAnalyzer no new findings
- [ ] Full Pester unit suite green
- [ ] Manual smoke test against a live Netbox: `Get-NBDCIMDevice -Brief -Fields 'id'` throws with a clear message
- [ ] Manual smoke test: `Get-NBDCIMDevice -Brief` returns devices without `config_context` in the response and without `omit=config_context` in the URI

## Spec

See `docs/superpowers/specs/2026-04-16-filter-exclusion-design.md` (included in this branch as the first commit).

## Follow-up

PR-2 will add `scripts/Verify-FilterExclusion.ps1` CI auditor and apply the helper to 121 remaining Get functions (including `Get-NBVirtualMachine` with its matching `IncludeConfigContext` logic and 5 parallel interaction tests).
EOF
)"
```

- [ ] **Step 2: Record the PR number**

Capture the URL output by `gh pr create` for reference when PR-2 is drafted (PR-2's description will link back to PR-1).
