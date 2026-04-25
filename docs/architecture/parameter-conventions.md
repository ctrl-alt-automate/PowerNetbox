---
title: Parameter conventions
---

# Parameter conventions

This page captures the conventions that 500+ PowerNetbox cmdlets follow. New
endpoints should match these patterns exactly. The
[`new-netbox-endpoint` skill](https://github.com/ctrl-alt-automate/PowerNetbox/blob/dev/.claude/skills/new-netbox-endpoint/SKILL.md)
contains full cmdlet templates and a pitfalls table; this page explains the *why*
behind each convention.

## Function naming

Pattern: `[Verb]-NB[Module][Resource]`

| Verb | HTTP method | Example |
|---|---|---|
| `Get-` | GET | `Get-NBDCIMDevice` |
| `New-` | POST | `New-NBIPAMAddress` |
| `Set-` | PATCH | `Set-NBVirtualMachine` |
| `Remove-` | DELETE | `Remove-NBDCIMSite` |

Module names match the NetBox application labels: `DCIM`, `IPAM`, `Virtualization`,
`Circuits`, `Tenancy`, `VPN`, `Wireless`, `Extras`, `Core`, `Users`.

## Snake_case parameter names

Parameter names match NetBox API field names, converted from `snake_case` to
`Pascal_Case_With_Underscores`: `-Device_Type`, `-Primary_IP4`, `-Mark_Utilized`.
This one-to-one mapping keeps `BuildURIComponents` simple (it lowercases and
adds underscores when building the request body) and means contributors can copy
field names straight from the NetBox API docs without a translation step.

## Nullable[T] for FK clearing

When a `Set-*` function needs to allow callers to clear a foreign-key field by
PATCHing JSON `null`, use `[Nullable[uint64]]`:

```powershell
[Nullable[uint64]]$Installed_Device
```

`$PSBoundParameters` includes the key with a `$null` value when the caller passes
`-Installed_Device $null`, and `ConvertTo-Json` serializes `$null` as JSON `null`
on both PowerShell 5.1 and 7. This pattern was first introduced for
`Set-NBDCIMDeviceBay -Installed_Device` (PR #366) and is now used on FK parameters
across Set-NBDCIMDevice, Set-NBDCIMInterface, and others.

```powershell
# Clears the Installed_Device pointer (decommission a device bay)
Set-NBDCIMDeviceBay -Id 5 -Installed_Device $null
```

## Empty-string sentinel for string-field clearing

Not all fields clear via `null`. Django's data model distinguishes:

- **`null=True`** (OpenAPI `nullable: true`) -- the column can hold `NULL`. Clear
  by sending JSON `null`. In PowerShell, use `[Nullable[T]]` for typed fields, or
  `[AllowEmptyString()] [ValidateSet('...', '')]` for enum strings and translate
  `''` to `$null` in `process{}` before calling `BuildURIComponents`.

- **`blank=True` without `null=True`** (most `description`, `label`, `comments`
  fields on NetBox's `PrimaryModel` base class) -- the column stores an empty
  string, never `NULL`. Clear by sending JSON `""`. In PowerShell, use plain
  `[string]$Description` and document that `-Description ''` clears the field.
  Sending `$null` to a `nullable: false` field returns HTTP 400.

```powershell
# Clears a nullable enum field (Interface.duplex -- nullable: true)
Set-NBDCIMInterface -Id 12 -Duplex ''   # '' is sentinel, translated to null in process{}

# Clears a blank-only string field (Device.description -- nullable: false)
Set-NBDCIMDevice -Id 7 -Description ''  # sends JSON "" directly
```

Before adding a new nullable or clearable parameter, query the live NetBox schema
at `/api/schema/?format=json` to get authoritative `nullable` flags for the field.
The wrong pattern produces a silent 400 with a clear server error message, but it's
faster to check upfront.

## ValidateRange + Nullable conflict

`[ValidateRange]` fires before `[Nullable[T]]` binding. As a result, passing
`$null` to a parameter decorated with both `[ValidateRange(...)]` and
`[Nullable[int]]` throws `ValidationMetadataException` before the cmdlet body
runs.

For `Set-*` functions that need null-clearing on a ranged field, drop
`[ValidateRange]` on the `Set-` version and rely on server-side validation.
The first time this surfaced was `Set-NBDCIMInterface -RF_Channel_Frequency` and
`-RF_Channel_Width` in PR #398. The paired `New-*` function can keep
`[ValidateRange]` since it never needs to send null.

## ValidateSet drift prevention

NetBox adds, renames, or removes choices in its ChoiceSet classes on every minor
release. PowerNetbox's `[ValidateSet]` decorators must track these changes; stale
values cause callers to get an unhelpful validation error rather than the real API
error.

Past examples of drift: Interface Mode (#360), interface types (#369), branch
status values (#385), Cable_Profile prefixes (#389).

To detect drift systematically, run:

```powershell
./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v4.5.8
./scripts/Verify-ValidateSetParity.ps1 -FailOnMismatch   # CI gate
```

The script matches every `[ValidateSet]` in `Functions/` to NetBox's ChoiceSet
classes using a weighted scoring algorithm and reports discrepancies.
`scripts/validateset-parity-exclusions.txt` holds the intentional deviations
(HTTP verbs, Bootstrap button classes, backward-compat legacy values).

**Run this on every NetBox compat bump** before opening the compat PR.

## Common-parameter groups

Every cmdlet's reference page includes collapsible "Common parameters" blocks
via snippet-includes. The three snippet files in `docs-build/snippets/` cover:

- `common-request-params.md` -- `-Raw` and authentication context
- `common-pagination-params.md` -- `-All`, `-PageSize`, `-Brief`, `-Fields`, `-Omit`
- `common-bulk-params.md` -- `-InputObject`, `-BatchSize`, `-Force`

For the prose explanation of these parameters, see
[Reference -- Common parameters](../reference/common-parameters.md).

## ASCII-only in .ps1 files

`.ps1` files must contain only ASCII characters. PowerShell 5.1 on Windows parses
`.ps1` files as Windows-1252 by default when no UTF-8 BOM is present. Non-ASCII
characters -- em-dashes, en-dashes, curly quotes, Unicode arrows -- cause misleading
parse errors like `Missing closing ')' in expression` that obscure the real cause.

This constraint applies to identifiers, string literals, `#region` labels, and
test `Describe`/`Context`/`It` names in `.ps1` and `.psm1` files. Markdown
documentation files, commit messages, and `.txt` files are exempt.

```powershell
# Wrong -- em-dash in a Pester context name breaks PS 5.1
Context "Interface Mode - Q-in-Q support (#394)"   # use ASCII hyphen-minus

# Wrong -- curly quotes in a comment
# "description" field   # use straight ASCII quotes if quoting inline
```

Before opening a PR that touches `.ps1` files, run:

```bash
grep -rn "—\|–\|\xe2\x80\x98\|\xe2\x80\x99" Functions/ Tests/
```

to catch non-ASCII before CI does.
