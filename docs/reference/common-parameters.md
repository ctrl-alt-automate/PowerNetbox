---
title: Common parameters
---

# Common parameters

PowerNetbox cmdlets share a small set of parameters that appear across most or all
functions. Rather than repeat them on every per-cmdlet reference page, they are
documented once here and included as collapsible blocks on each page.

## Request parameters (every cmdlet)

**`-Raw`** -- When set, the cmdlet returns the raw `PSCustomObject` response from
the API instead of the default projected result. Use it when you need fields that
the default view omits, or when you want to pipe the full object into a custom
transformation.

```powershell
# Default: returns a structured DeviceObject
Get-NBDCIMDevice -Id 42

# Raw: returns whatever the API sends, unshaped
Get-NBDCIMDevice -Id 42 -Raw
```

**Authentication context** is handled once by `Connect-NBAPI` and cached for the
session. No per-cmdlet token or credential parameter exists -- the connection state
is global to the module.

For details on retry logic and what happens when the API returns an error, see
[Architecture -- Error handling](../architecture/error-handling.md).

## Pagination and field filtering (Get- cmdlets)

These parameters are available on every `Get-NB*` cmdlet.

**`-All`** -- Retrieves all matching records across multiple API pages. Without
this switch, only the first page (up to `-PageSize` records) is returned.

```powershell
# Get first 100 devices (default page)
Get-NBDCIMDevice

# Get every device in NetBox, regardless of count
Get-NBDCIMDevice -All
```

**`-PageSize <int>`** -- Number of records per API request. Default is 100,
maximum is 1000 (enforced by NetBox). Larger values mean fewer round-trips but
higher per-call memory and latency. Tune this for your dataset size; the default
is a reasonable starting point.

**Field filtering** -- three mutually exclusive switches control which fields NetBox
returns:

**`-Brief`** -- Returns NetBox's "brief" projection: `id`, `url`, `display`, and
the key identifying field (`name`, `address`, etc.). Best for existence checks,
drop-down population, or when you only need IDs.

**`-Fields <string[]>`** -- Returns only the named fields. Unknown field names are
silently ignored by NetBox, so typos produce a sparse response rather than an error.
Example: `-Fields id,name,status`.

**`-Omit <string[]>`** -- Returns the default projection minus the named fields.
The most common use is `-Omit config_context`, which skips an expensive server-side
expansion and can make list queries 10-100x faster on large datasets.

!!! warning "Mutual exclusion"
    Passing two or more of `-Brief`, `-Fields`, `-Omit` in the same call raises
    `ParameterBindingException` with a message that names the conflicting
    parameters. Pick one filter strategy per call.

    This is enforced on `Get-NBDCIMDevice`, `Get-NBIPAMAddress`, `Get-NBVPNTunnel`,
    and all 123 Get- cmdlets as of v4.5.8.0.

## Bulk operations (selected New-/Set-/Remove- cmdlets)

**`-InputObject`** -- Accepts objects via the pipeline for bulk processing. Each
object must match the shape the cmdlet expects: for `Set-` and `Remove-`, a
`PSCustomObject` or hashtable with an `Id` property; for `New-`, the full field
set needed to create the resource.

**`-BatchSize <int>`** -- Number of objects sent per bulk API call. Default is 50.
NetBox processes the batch atomically at the API level, so a higher batch size
reduces round-trips but increases the blast radius if any item in the batch
fails validation.

**`-Force`** -- Skips the `ShouldProcess` confirmation prompt. Required for
non-interactive or scripted bulk operations.

```powershell
# Bulk-create 100 devices from a pipeline
1..100 | ForEach-Object {
    [PSCustomObject]@{
        Name        = "server-$_"
        Role        = 1
        Device_Type = 1
        Site        = 1
    }
} | New-NBDCIMDevice -BatchSize 50 -Force
```

Cmdlets that support bulk operations: `New-NBDCIMDevice`, `New-NBDCIMInterface`,
`New-NBIPAMAddress`, `New-NBIPAMPrefix`, `New-NBIPAMVLAN`, `New-NBVirtualMachine`,
`New-NBVirtualMachineInterface`, `Set-NBDCIMDevice`, `Remove-NBDCIMDevice`.

For error handling of partial-success batches, see
[Guides -- Bulk operations](../guides/bulk-operations.md).

## What is NOT in the common set

- **Per-resource filter parameters** (`-Name`, `-Site`, `-Status`, etc.) are
  documented on the individual cmdlet's reference page.
- **Authentication** is a one-time `Connect-NBAPI` concern, not a per-cmdlet
  parameter.
- **Branch context** is set module-wide via `Enter-NBBranch` / `Exit-NBBranch`,
  not via a per-cmdlet parameter.
