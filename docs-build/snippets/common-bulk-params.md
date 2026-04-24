These parameters apply on cmdlets that support bulk operations via the pipeline:

**`-InputObject`** — Accepts objects via the pipeline for bulk processing. Each object must match the shape required by the cmdlet (e.g. a hashtable or PSCustomObject with `Id` for `Set-`/`Remove-`, or full field set for `New-`).

**`-BatchSize <int>`** — Number of items sent per bulk API call. Default is 50. Larger batches reduce round-trips but increase the blast radius of a single API failure.

**`-Force`** — Skips the `ShouldProcess` confirmation prompt. Required for non-interactive / scripted bulk operations.

For the full pattern including error handling of partial-success batches, see [Guides -> Bulk Operations](../../guides/bulk-operations.md).
