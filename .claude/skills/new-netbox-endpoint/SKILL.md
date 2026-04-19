---
name: new-netbox-endpoint
description: Use when adding a new NetBox REST API endpoint to PowerNetbox as a set of PowerShell cmdlets (Get / New / Set / Remove). Covers function templates, parameter conventions, test patterns, ValidateSet parity checks, and the PS 5.1 / Nullable / Tags gotchas that recur on this codebase.
---

# Adding a new NetBox endpoint to PowerNetbox

## Overview

Each NetBox endpoint maps to up to four cmdlets: `Get-NB*`, `New-NB*`,
`Set-NB*`, `Remove-NB*`. Each cmdlet is one file under
`Functions/<Module>/<Resource>/`, and all four share a consistent shape
driven by a central `InvokeNetboxRequest` + `BuildURIComponents` helpers.
The job of this skill is to make the fifth, fiftieth, and five-hundredth
endpoint look identical.

## When this applies

- NetBox ships a new API endpoint (e.g. new minor release adds `/api/dcim/<x>/`).
- An issue asks for a missing resource (pattern seen on #356, #362-#364, #383).
- A drift report from `scripts/Verify-ValidateSetParity.ps1` flags a new
  enum you want to expose.
- You are porting a cmdlet from community code (e.g. NetboxPS) to PowerNetbox conventions.

## Workflow (in order)

1. **Scope** — Is the endpoint read-only, read-write, or read-only-and-ephemeral (job-style)?
   That decides how many of the four cmdlets you need. Get-only is fine; you
   don't need `New`/`Set`/`Remove` if NetBox doesn't expose POST/PATCH/DELETE.
2. **Research** — skim the NetBox OpenAPI spec at
   `https://<host>/api/schema/` (or for dev: use
   `/.claude/commands/netbox-api.md` shorthand). Note every required field,
   every ChoiceSet, every pagination quirk.
3. **ValidateSet parity** — for every `ValidateSet` attribute you add,
   run `scripts/Verify-ValidateSetParity.ps1 -Function <Name>` against the
   NetBox version you target. Drift is the single most common bug class on
   this codebase (#360, #365, #385, #389, #392).
4. **Implement** — one file per cmdlet, copy from the templates below.
5. **Test** — one `Context "<cmdlet>"` per cmdlet in
   `Tests/<Module>.Tests.ps1`. Mock at the `InvokeNetboxRequest` level,
   not `Invoke-RestMethod`, unless the cmdlet bypasses it (file uploads, SVG).
6. **Build + verify** — `./deploy.ps1 -Environment dev -SkipVersion`,
   then `Invoke-Pester ./Tests/<Module>.Tests.ps1`.
7. **Revert build artefacts before commit** —
   `git checkout PowerNetbox.psd1` (deploy.ps1 updates its date).

## Cmdlet templates

All four templates share: `[CmdletBinding()]`, explicit `process {}` for
pipeline support, `-Raw` switch, `Write-Verbose` for any operational
logging (never `Write-Host` in non-interactive paths).

### GET

```powershell
function Get-NB[Module][Resource] {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param (
        [switch]$All,
        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName)]
        [uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,
        [uint16]$Limit,
        [uint16]$Offset,
        [switch]$Brief,
        [string[]]$Fields,
        [string[]]$Omit,
        [switch]$Raw
    )
    process {
        # Enforce mutual exclusion — user can pick ONE projection strategy.
        # See Functions/Helpers/AssertNBMutualExclusiveParam.ps1 (PR #397/#400).
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'

        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($i in $Id) {
                    InvokeNetboxRequest -URI (BuildNewURI -Segments @('<module>', '<resource>', $i)) -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('<module>', '<resource>'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() `
                    -ParametersDictionary $PSBoundParameters `
                    -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest `
                    -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) `
                    -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
```

### NEW

```powershell
function New-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [object[]]$Tags,   # prefer [object[]] over [string[]] / [uint64[]] — see Pitfalls
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('<module>', '<resource>'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() `
            -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create <Resource>')) {
            InvokeNetboxRequest `
                -URI (BuildNewURI -Segments $URIComponents.Segments) `
                -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
```

### SET (PATCH)

```powershell
function Set-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [uint64]$Id,
        [string]$Name,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('<module>', '<resource>', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() `
            -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update <Resource>')) {
            InvokeNetboxRequest `
                -URI (BuildNewURI -Segments $URIComponents.Segments) `
                -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
```

### REMOVE

```powershell
function Remove-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete <Resource>')) {
            InvokeNetboxRequest `
                -URI (BuildNewURI -Segments @('<module>', '<resource>', $Id)) `
                -Method DELETE -Raw:$Raw
        }
    }
}
```

## Test pattern

Most test files mock at the **module API surface** — that is,
`InvokeNetboxRequest` — not the lower-level `Invoke-RestMethod`. Nice
side effect: your test doesn't care about auth headers, retry logic,
or cross-platform HTTP differences.

```powershell
Describe "<Module> tests" -Tag '<Module>' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'InvokeNetboxRequest'    -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }   # defaults don't apply to mocks
                'Uri'    = $URI.Uri.AbsoluteUri                        # AbsoluteUri encodes spaces as %20
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
        }
        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Get-NB<Module><Resource>" {
        It "Should request the list endpoint" {
            $r = Get-NB<Module><Resource>
            $r.Method | Should -Be 'GET'
            $r.Uri    | Should -Be 'https://netbox.domain.com/api/<module>/<resource>/'
        }
    }
}
```

Mock at `Invoke-RestMethod` level only when the cmdlet bypasses
`InvokeNetboxRequest`: `New-NBImageAttachment` (multipart form),
`Export-NBRackElevation` SVG mode, `ErrorHandling.Tests.ps1`,
`Setup.Tests.ps1`, `CrossPlatform.Tests.ps1`, `Branching.Tests.ps1`.

## ValidateSet parity — run it

Every time you add or edit a `ValidateSet`:

```pwsh
./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v<x.y.z>
# Or scope to the cmdlet you touched:
./scripts/Verify-ValidateSetParity.ps1 -Function New-NBDCIMInterface
```

If your parameter deliberately has values NetBox's choices.py doesn't have
(e.g. the `''` empty-string sentinel for PATCH null-clearing, or local
meta-values like `'Both'` for rack elevation), add an exemption to
`scripts/validateset-parity-exclusions.txt` with a comment explaining why.

## Pitfalls (things that have bitten us more than once)

| Pitfall | Cause | Fix |
|---|---|---|
| Windows PS 5.1 CI fails with "Missing closing '}'" at some line far from the real issue | Non-ASCII char (em-dash U+2014, arrows, curly quotes) in a `.ps1` file without a UTF-8 BOM — PS 5.1 parses as Windows-1252 | Stay ASCII in `.ps1` identifiers and test titles. Markdown `.md` files are unaffected. (Recurring: PR #398, PR #404) |
| `[ValidateRange]` + `[Nullable[int]]` throws `ValidationMetadataException` on `$null` | ValidateRange binds before Nullable wrapping | Drop `[ValidateRange]` on `Set-*` versions that need null-clearing; rely on server-side validation (PR #398) |
| `[AllowNull()] [ValidateSet(...)] [string]$X` rejects `$null` | PS coerces `$null` → `""` before ValidateSet runs | Use `[AllowEmptyString()] [ValidateSet('a','b','',...)]` and translate `''` → `$null` in `process{}` before `BuildURIComponents` (PR #401) |
| Pester mock gets `$null` for default-valued params | Default values do not apply inside `MockWith` | Add explicit defaults inside the mock (see test template above) |
| `ConvertTo-Json` mangles nested objects at the default depth | `ConvertTo-Json` defaults to `-Depth 2` | Pass `-Depth 10` explicitly when needed |
| PSCustomObject iterated like a hashtable throws | PSCustomObject is not a hashtable | Use `$obj.PSObject.Properties` to iterate |
| Build artefact noise in git diff | `deploy.ps1` updates `PowerNetbox.psd1` date on every build | `git checkout PowerNetbox.psd1` before staging |
| Bulk operations pipeline runs unboundedly | No client throttle by default | `Send-NBBulkRequest` has `MaxItems = 10000` cap; pass `-BatchSize` to size each POST |
| Pagination `.next` follow to wrong host | Server-controlled URL could be attacker-controlled | `InvokeNetboxRequest` validates origin against original URI via `GetLeftPart(Authority)` (PR #404) |

## Parameter naming conventions

- **Snake-case** in the cmdlet body: parameters map 1:1 to NetBox API fields.
  `Device_Type` (PS) → `device_type` (API) — done automatically by `BuildURIComponents`.
- `Id` (not `ID`) for PowerShell consistency with pipeline binding.
- `Tags` should be `[object[]]` — see Pitfalls. Older cmdlets use
  `[string[]]` or `[uint64[]]`; left as-is for compat, but new code uses `[object[]]`.
- `-Raw` switch on every cmdlet (returns the full response object rather than
  the `.results` array).
- Boolean API fields: use `[bool]`, not `[switch]`. Switches mean "omitted
  vs supplied" but NetBox treats missing vs false differently.

## Verification before PR

- [ ] `./deploy.ps1 -Environment dev -SkipVersion` — build succeeds, no duplicate function names
- [ ] `Invoke-Pester ./Tests/<Module>.Tests.ps1` — all green
- [ ] `Invoke-ScriptAnalyzer -Path ./Functions/<Module>/<new file>.ps1` — clean
- [ ] `./scripts/Verify-ValidateSetParity.ps1` — no new drift findings
- [ ] `./scripts/Verify-FilterExclusion.ps1` — if you touched any `Get-NB*.ps1`, see `docs/guides/` if unfamiliar
- [ ] `grep -nP "[^\x00-\x7F]" Functions/... Tests/...` — no non-ASCII in `.ps1` files
- [ ] `git checkout PowerNetbox.psd1` — revert build-artefact drift before committing

## Pointers

| Topic | File |
|---|---|
| Central HTTP helper | `Functions/Helpers/InvokeNetboxRequest.ps1` |
| Body + URL parameter assembly | `Functions/Helpers/BuildURIComponents.ps1` |
| URL builder | `Functions/Helpers/BuildNewURI.ps1` |
| Auth header construction (v1 vs v2) | `Functions/Helpers/Get-NBRequestHeaders.ps1` |
| Mutex helper for Brief / Fields / Omit | `Functions/Helpers/AssertNBMutualExclusiveParam.ps1` |
| Bulk operations | `Functions/Helpers/Send-NBBulkRequest.ps1` |
| ValidateSet parity script | `scripts/Verify-ValidateSetParity.ps1` |
| ValidateSet parity exceptions | `scripts/validateset-parity-exclusions.txt` |
| Filter exclusion auditor | `scripts/Verify-FilterExclusion.ps1` |
| Exemption file for filter auditor | `scripts/filter-exclusion-exemptions.txt` |
| NetBox best-practices reference | `../netbox-best-practices/` (parent project dir) |
