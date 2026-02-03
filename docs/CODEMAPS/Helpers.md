# Helper Functions Reference

Internal helper functions used by PowerNetbox. These are **not exported** in production builds.

## Core Helpers

### InvokeNetboxRequest

**File:** `Functions/Helpers/InvokeNetboxRequest.ps1`

The central HTTP request handler. All API functions ultimately call this.

**Features:**
- Automatic v1/v2 token detection (`Token` vs `Bearer`)
- Branch context header injection (`X-NetBox-Branch`)
- Retry logic with exponential backoff (408, 429, 5xx)
- Cross-platform error body extraction
- Verbose logging with sensitive field redaction

```powershell
InvokeNetboxRequest -URI $uri -Method GET -Raw:$Raw
InvokeNetboxRequest -URI $uri -Method POST -Body $body
```

### BuildURIComponents

**File:** `Functions/Helpers/BuildURIComponents.ps1`

Converts `$PSBoundParameters` into URI segments and body parameters.

```powershell
$URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'Id'
# Returns: @{ Segments = [...]; Parameters = @{...} }
```

### BuildNewURI

**File:** `Functions/Helpers/BuildNewURI.ps1`

Constructs the full API URL from segments and query parameters.

```powershell
$URI = BuildNewURI -Segments @('dcim', 'devices') -Parameters @{ name = 'server01' }
# Returns: https://netbox.example.com/api/dcim/devices/?name=server01
```

### Get-NBRequestHeaders

**File:** `Functions/Helpers/Get-NBRequestHeaders.ps1`

Returns authentication and context headers for API requests.

```powershell
$headers = Get-NBRequestHeaders
# Returns: @{ Authorization = "Bearer nbt_..."; "X-NetBox-Branch" = "schema_id" }
```

### Send-NBBulkRequest

**File:** `Functions/Helpers/Send-NBBulkRequest.ps1`

Batch API operations with automatic chunking and error recovery.

```powershell
Send-NBBulkRequest -URI $uri -Method POST -Body $items -BatchSize 50
```

**Features:**
- Configurable batch size (default 50)
- Automatic fallback to individual requests on 500 errors
- Progress reporting via Write-Verbose

## Version Handling

### ConvertTo-NetboxVersion

**File:** `Functions/Helpers/ConvertTo-NetboxVersion.ps1`

Parses version strings into `[System.Version]` objects.

```powershell
ConvertTo-NetboxVersion "4.5.0-Docker-3.2.1"  # Returns [version]4.5.0
ConvertTo-NetboxVersion "v4.4.9-dev"          # Returns [version]4.4.9
```

### Test-NBMinimumVersion

**File:** `Functions/Helpers/Test-NBMinimumVersion.ps1`

Checks if connected Netbox meets minimum version requirement.

```powershell
if (Test-NBMinimumVersion -Version '4.5.0') {
    # Use v2 token features
}
```

## Error Handling

### GetNetboxAPIErrorBody

**File:** `Functions/Helpers/GetNetboxAPIErrorBody.ps1`

Extracts error body from failed API responses (handles Desktop vs Core PowerShell differences).

```powershell
$errorBody = GetNetboxAPIErrorBody -ErrorRecord $_
```

### Test-NBDeprecatedParameter

**File:** `Functions/Helpers/Test-NBDeprecatedParameter.ps1`

Warns about deprecated parameter usage.

```powershell
Test-NBDeprecatedParameter -ParameterName 'OldParam' -ReplacementName 'NewParam' -BoundParameters $PSBoundParameters
```

## Connection Utilities

### CheckNetboxIsConnected

**File:** `Functions/Helpers/CheckNetboxIsConnected.ps1`

Throws if no active Netbox connection exists.

```powershell
CheckNetboxIsConnected  # Throws if not connected
```

## Output Formatting

### ConvertTo-NBRackHTML / ConvertTo-NBRackMarkdown / ConvertTo-NBRackConsole

**Files:** `Functions/Helpers/ConvertTo-NBRack*.ps1`

Convert rack elevation data to various output formats.

```powershell
Get-NBDCIMRack -Id 1 | ConvertTo-NBRackMarkdown
```

## Supporting Files

### _Aliases.ps1

Defines function aliases (e.g., `gnbd` for `Get-NBDCIMDevice`).

### _ArgumentCompleters.ps1

Registers tab completion for common parameters (Site, Device, etc.).

### _BulkOperationResult.ps1

Defines the `BulkOperationResult` class for bulk operation responses.

## Architecture Notes

1. **No try/catch in API functions** - All error handling is centralized in `InvokeNetboxRequest`
2. **Helpers are internal** - Not exported in production builds
3. **Underscore prefix** - Files starting with `_` are not functions (aliases, completers, classes)
