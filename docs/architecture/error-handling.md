---
title: Error handling
---

# Error handling

PowerNetbox uses a **centralized error handler** in `InvokeNetboxRequest`
(`Functions/Helpers/InvokeNetboxRequest.ps1`). The 500+ public cmdlets
intentionally contain no `try`/`catch` blocks of their own.

## Why centralize

Putting error logic in a single place means retry behaviour, detailed error
messages, and cross-platform compatibility improvements apply immediately to every
cmdlet without per-function changes. It also keeps the API surface functions small
and predictable: they build a URI, call `InvokeNetboxRequest`, and return the
result. Anything unexpected surfaces as a terminating error with a consistent shape.

## Retry behaviour

`InvokeNetboxRequest` automatically retries on transient failures. The default
configuration is three attempts with exponential backoff starting at 1000 ms, with
added jitter to avoid thundering-herd problems when multiple scripts hit the same
NetBox instance simultaneously.

Retryable status codes: `408 Request Timeout`, `429 Too Many Requests`,
`500 Internal Server Error`, `502 Bad Gateway`, `503 Service Unavailable`,
`504 Gateway Timeout`.

Non-retryable status codes (4xx other than 408/429, and unexpected errors) surface
immediately without retrying.

Both `-MaxRetries` and `-RetryDelayMs` are parameters on `InvokeNetboxRequest`
itself; the defaults are appropriate for interactive use. CI scripts that need
faster failure can override them.

## Cross-platform error body extraction

PowerShell Desktop (5.1) and PowerShell Core (7+) handle HTTP error response bodies
differently. On Desktop, the body is accessible only through the exception's response
stream; on Core, `Invoke-RestMethod` raises an `HttpResponseException` that exposes
the body more directly. The internal helper `GetNetboxAPIErrorBody` abstracts this
difference so the rest of the module sees a single string.

## Status code to ErrorCategory mapping

`InvokeNetboxRequest` maps HTTP status codes to PowerShell `ErrorCategory` values,
which allows callers to use typed `catch` blocks:

| HTTP status | ErrorCategory |
|---|---|
| 400 Bad Request | `InvalidArgument` |
| 401 Unauthorized | `AuthenticationError` |
| 403 Forbidden | `PermissionDenied` |
| 404 Not Found | `ObjectNotFound` |
| 405 Method Not Allowed | `InvalidOperation` |
| 408 Request Timeout | `OperationTimeout` |
| 409 Conflict | `ResourceExists` |
| 429 Too Many Requests | `LimitsExceeded` |
| 5xx | `ConnectionError` |

```powershell
try {
    Get-NBDCIMDevice -Id 9999
} catch [System.Management.Automation.ErrorRecord] {
    if ($_.CategoryInfo.Category -eq [System.Management.Automation.ErrorCategory]::ObjectNotFound) {
        Write-Host "Device not found"
    }
}
```

## Branch-aware diagnostics

When a 401 or 403 error occurs while a branch context is active (set via
`Enter-NBBranch`), the error message includes:

- The active branch name and `schema_id`
- Targeted troubleshooting hints: verify that the token has write permissions to
  the branch, check whether the branch has already been merged or archived, and
  a suggestion to run `Exit-NBBranch` to isolate whether the error is
  branch-specific.

When no branch is active, 401/403 messages use the standard format without branch
context. Added in v4.5.7.0 (issue #382, reported by @Christophoclese).

## When local try/catch is justified

A small set of helper, setup, branching, and feature-detection functions retain their
own `try`/`catch` or `try`/`finally` blocks. Each falls into one of three categories:

**Feature detection** -- `Test-NBBranchingAvailable` and `Test-NBAuthentication`
return a `bool` rather than throwing. Callers use these to probe capability before
committing to an operation.

**Resource cleanup** -- `Invoke-NBInBranch` uses `try`/`finally` to guarantee
`Exit-NBBranch` runs even if the script block throws. The `finally` block is the
entire point; without it, a failure would leave the session stuck in the wrong
branch context.

**Setup and configuration** -- `Connect-NBAPI` and the SSL helper functions have
special initialization needs (bootstrapping the connection state, validating
certificates) that don't fit the standard request-response flow. Similarly,
`InvokeNetboxRequest` itself, `Send-NBBulkRequest`, and `Wait-NBBranch` handle
error aggregation and status polling outside the central pattern.

**Safe parsing** -- `ConvertTo-NetboxVersion` wraps version-string parsing in a
`try`/`catch` to return `$null` on malformed input rather than propagating a
terminating error during connection setup. `GetNetboxAPIErrorBody` abstracts
cross-platform error body extraction.

**Content-handling exceptions** -- `Get-NBDCIMRackElevation` (SVG mode) and
`New-NBImageAttachment` (multipart form upload) bypass `InvokeNetboxRequest` and
require their own error handling for those specialized code paths.

**Do not** add `try`/`catch` to API functions unless you need to: (a) return a bool
instead of throwing, (b) guarantee cleanup via `finally`, or (c) transform an error
into substantively different behaviour. Adding error handling "just in case" to a
cmdlet that calls `InvokeNetboxRequest` duplicates the central handler and produces
inconsistent error shapes.
