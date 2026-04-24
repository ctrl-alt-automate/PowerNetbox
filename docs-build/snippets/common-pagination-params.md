These parameters control how `Get-` cmdlets paginate and shape their responses:

**`-All`** — Retrieves all matching records across multiple pages. Without this, only the first page (up to `-PageSize`) is returned.

**`-PageSize <int>`** — Number of records per API call. Default is 100, maximum 1000 (enforced by NetBox). Larger values mean fewer round-trips but more memory.

**Field filtering — these three are mutually exclusive:**

**`-Brief`** — Returns the NetBox "brief" projection: `id`, `url`, `name` (or equivalent). Fastest for existence checks or populating drop-downs.

**`-Fields <string[]>`** — Returns only the named fields. Example: `-Fields id,name,status`. Unknown field names are silently ignored by NetBox.

**`-Omit <string[]>`** — Returns the default projection minus the named fields. Commonly `-Omit config_context` to skip the expensive context expansion.

!!! warning "Mutual exclusion"
    Passing two or more of `-Brief`, `-Fields`, `-Omit` raises `ParameterBindingException`
    with a clear message naming the conflicting parameters. Pick one filter strategy per call.
