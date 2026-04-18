# Privacy Policy

PowerNetbox is a local PowerShell module. It does not collect, transmit,
or phone home with any user data.

## What PowerNetbox does

- Sends HTTP(S) requests from the user's machine to the NetBox host the
  user explicitly configured via `Connect-NBAPI`.
- Reads the NetBox API token the user supplied (from a `PSCredential`,
  `SecureString`, or environment variable) and includes it in the
  `Authorization` header of those requests.
- Writes verbose / debug output to the console when the user opts in via
  `-Verbose` or `$VerbosePreference`. Tokens are redacted from this output
  — see `Functions/Helpers/InvokeNetboxRequest.ps1`.

## What PowerNetbox does not do

- No telemetry, analytics, or usage metrics are transmitted anywhere.
- No data is sent to the module maintainer, PSGallery, GitHub, or any
  third party.
- No files are written outside of what the user's own cmdlets produce
  (e.g. `Export-NBRackElevation` writes to a path the user specified).
- No network requests are made to hosts the user did not configure.

## Data that does leave the user's machine

Only what is sent to the user-configured NetBox host via the REST API.
The user controls the host, the token, and every cmdlet invocation.
PowerNetbox is merely a convenience layer over `Invoke-RestMethod` /
`Invoke-WebRequest`.

## Logs and diagnostics

- Verbose output goes to the PowerShell console stream only.
- Debug output similarly console-only.
- Error objects include the response body for troubleshooting; the
  Authorization header is redacted from that body. See
  `BuildDetailedErrorMessage` in `InvokeNetboxRequest.ps1`.

## Credentials

- Tokens supplied via `Connect-NBAPI -Credential` are stored in-memory
  as `[SecureString]` for the session lifetime.
- On Windows, SecureString uses DPAPI (process-scoped entropy).
  On Linux and macOS, PowerShell's SecureString is an obfuscation only
  — per Microsoft documentation it is **not** a security boundary on
  non-Windows platforms. Use `.env` with OS file permissions, or a
  secret manager of your choice, to protect tokens at rest.
- Tokens are never written to disk by PowerNetbox itself.
- `Disconnect-NBAPI` clears the in-memory credential.

## Questions

Open a GitHub Discussion or email `31536997+ctrl-alt-automate@users.noreply.github.com`.

_Last updated: 2026-04-18._
