function Get-NBRequestHeaders {
<#
    .SYNOPSIS
        Get standard request headers for Netbox API calls

    .DESCRIPTION
        Returns a hashtable containing the Authorization header (with proper v1/v2 token format)
        and optionally the X-NetBox-Branch header if a branch context is active.

        This function centralizes header construction to ensure consistent authentication
        and branch context handling across all API request functions.

    .PARAMETER Branch
        Optional explicit branch schema_id to use instead of the stack context

    .PARAMETER IncludeBranchContext
        Whether to include branch context header. Defaults to $true.

    .EXAMPLE
        $headers = Get-NBRequestHeaders
        Invoke-WebRequest -Uri $uri -Headers $headers

    .EXAMPLE
        $headers = Get-NBRequestHeaders -Branch "abc123"
        # Uses explicit branch instead of stack context

    .EXAMPLE
        $headers = Get-NBRequestHeaders -IncludeBranchContext:$false
        # Only returns Authorization header, no branch context
#>

    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$Branch,

        [switch]$IncludeBranchContext = $true
    )

    $creds = Get-NBCredential
    $token = $creds.GetNetworkCredential().Password

    # Detect token format: v2 tokens start with 'nbt_' and use Bearer auth
    $authHeader = if ($token -match '^nbt_') {
        "Bearer $token"
    }
    else {
        # Legacy v1 token format
        "Token $token"
    }

    $headers = @{
        'Authorization' = $authHeader
    }

    # Add branch context if requested
    if ($IncludeBranchContext) {
        # Determine effective branch context: explicit param > stack context > main
        $effectiveBranchContext = if ($Branch) {
            # Explicit -Branch parameter (schema_id string)
            $Branch
        }
        elseif ($script:NetboxConfig.BranchStack -and $script:NetboxConfig.BranchStack.Count -gt 0) {
            # Get context from stack
            $script:NetboxConfig.BranchStack.Peek()
        }
        else {
            $null
        }

        if ($effectiveBranchContext) {
            # Extract schema_id - handle both object (new) and string (legacy/explicit) formats
            $schemaId = if ($effectiveBranchContext -is [PSCustomObject]) {
                if (-not $effectiveBranchContext.SchemaId) {
                    throw "Invalid branch context object: 'SchemaId' property is missing or empty."
                }
                $effectiveBranchContext.SchemaId
            }
            else {
                # Assume it's already a schema_id string (e.g., from -Branch parameter)
                $effectiveBranchContext
            }

            $headers['X-NetBox-Branch'] = $schemaId

            # Log with branch name if available, otherwise just schema_id
            $displayName = if ($effectiveBranchContext -is [PSCustomObject] -and $effectiveBranchContext.Name) {
                "$($effectiveBranchContext.Name) ($schemaId)"
            }
            else {
                $schemaId
            }
            Write-Verbose "Using branch context: $displayName"
        }
    }

    return $headers
}
