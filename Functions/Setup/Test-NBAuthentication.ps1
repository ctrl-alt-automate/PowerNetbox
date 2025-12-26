<#
.SYNOPSIS
    Tests the current Netbox API authentication.

.DESCRIPTION
    Validates the current API token by calling the authentication-check endpoint.
    On Netbox 4.5+, uses the native /api/authentication-check/ endpoint.
    On older versions, falls back to calling Get-NBVersion as an authenticated check.

    Returns $true if authenticated, $false otherwise.
    Use -Detailed to get full user information (4.5+) or error details.

.PARAMETER Detailed
    Return detailed information instead of just $true/$false.
    On Netbox 4.5+: Returns the authenticated user object.
    On older versions or errors: Returns a PSCustomObject with Authenticated and Error properties.

.PARAMETER Raw
    Return the raw API response (only applies when -Detailed is used).

.EXAMPLE
    Test-NBAuthentication

    Returns $true if the current token is valid, $false otherwise.

.EXAMPLE
    Test-NBAuthentication -Detailed

    Returns the authenticated user object on Netbox 4.5+, or error details if authentication fails.

.EXAMPLE
    if (Test-NBAuthentication) {
        # Token is valid, proceed with operations
        Get-NBDCIMDevice -All
    }

.OUTPUTS
    [bool] When called without -Detailed
    [PSCustomObject] When called with -Detailed

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Test-NBAuthentication {
    [CmdletBinding()]
    [OutputType([bool], [PSCustomObject])]
    param (
        [switch]$Detailed,

        [switch]$Raw
    )

    process {
        # Check if we're connected first
        try {
            $null = CheckNetboxIsConnected
        }
        catch {
            if ($Detailed) {
                return [PSCustomObject]@{
                    Authenticated = $false
                    User          = $null
                    Error         = "Not connected to Netbox. Use Connect-NBAPI first."
                    NetboxVersion = $null
                }
            }
            return $false
        }

        $currentVersion = $script:NetboxConfig.ParsedVersion

        # Try the new 4.5+ endpoint first if version supports it
        if ($null -eq $currentVersion -or $currentVersion -ge [version]'4.5.0') {
            try {
                $Segments = [System.Collections.ArrayList]::new(@('authentication-check'))
                $URI = BuildNewURI -Segments $Segments

                $result = InvokeNetboxRequest -URI $URI -Raw:$Raw

                if ($Detailed) {
                    return [PSCustomObject]@{
                        Authenticated = $true
                        User          = $result
                        Error         = $null
                        NetboxVersion = $script:NetboxConfig.NetboxVersion.'netbox-version'
                    }
                }
                return $true
            }
            catch {
                $statusCode = $null
                if ($_.Exception.Response) {
                    $statusCode = [int]$_.Exception.Response.StatusCode
                }

                # 404 means endpoint doesn't exist (older Netbox), try fallback
                if ($statusCode -eq 404) {
                    Write-Verbose "authentication-check endpoint not found, using fallback method"
                    return Test-NBAuthenticationFallback -Detailed:$Detailed
                }

                # 401/403 means authentication failed
                if ($statusCode -in @(401, 403)) {
                    if ($Detailed) {
                        return [PSCustomObject]@{
                            Authenticated = $false
                            User          = $null
                            Error         = $_.Exception.Message
                            NetboxVersion = $script:NetboxConfig.NetboxVersion.'netbox-version'
                        }
                    }
                    return $false
                }

                # Other errors - rethrow or return false
                if ($Detailed) {
                    return [PSCustomObject]@{
                        Authenticated = $false
                        User          = $null
                        Error         = $_.Exception.Message
                        NetboxVersion = $script:NetboxConfig.NetboxVersion.'netbox-version'
                    }
                }
                return $false
            }
        }
        else {
            # Known older version, use fallback directly
            return Test-NBAuthenticationFallback -Detailed:$Detailed
        }
    }
}

function Test-NBAuthenticationFallback {
    <#
    .SYNOPSIS
        Fallback authentication check for Netbox versions prior to 4.5.

    .DESCRIPTION
        Uses Get-NBVersion as an authenticated API call to verify the token is valid.
        This is used when the /api/authentication-check/ endpoint is not available.
    #>
    [CmdletBinding()]
    [OutputType([bool], [PSCustomObject])]
    param (
        [switch]$Detailed
    )

    try {
        Write-Verbose "Using fallback authentication check (Get-NBVersion)"
        $version = Get-NBVersion -ErrorAction Stop

        if ($Detailed) {
            return [PSCustomObject]@{
                Authenticated = $true
                User          = $null  # Not available in fallback mode
                Error         = $null
                NetboxVersion = $version.'netbox-version'
                Note          = "Detailed user info not available on Netbox versions prior to 4.5"
            }
        }
        return $true
    }
    catch {
        if ($Detailed) {
            return [PSCustomObject]@{
                Authenticated = $false
                User          = $null
                Error         = $_.Exception.Message
                NetboxVersion = $null
            }
        }
        return $false
    }
}
