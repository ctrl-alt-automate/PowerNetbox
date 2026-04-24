These parameters are available on every cmdlet that hits the NetBox API:

**`-Raw`** — When set, returns the raw PSCustomObject response from the API instead of the parsed / wrapped result. Useful for debugging or when you need fields that the default projection doesn't surface.

**Authentication context** is provided automatically by `Connect-NBAPI`. No per-cmdlet authentication parameter is needed.

For details on error handling and retry behaviour, see [Architecture -> Error handling](../../architecture/error-handling.md).
