function VerifyAPIConnectivity {
    <#
    .SYNOPSIS
        Verifies connectivity to the Netbox API.

    .DESCRIPTION
        Tests API connectivity by calling the /api/status/ endpoint, which returns
        Netbox version information and verifies authentication is working.
        This is the recommended health check endpoint for Netbox 3.x and 4.x.

    .OUTPUTS
        [PSCustomObject] The status response containing Netbox version info.

    .EXAMPLE
        $status = VerifyAPIConnectivity
        Write-Verbose "Connected to Netbox $($status.'netbox-version')"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # Use /api/status/ for comprehensive health check
    # This endpoint returns version info and validates authentication
    $uriSegments = [System.Collections.ArrayList]::new(@('status'))

    $uri = BuildNewURI -Segments $uriSegments -SkipConnectedCheck

    try {
        $status = InvokeNetboxRequest -URI $uri -Raw

        # Validate we got a proper response
        if ($status.'netbox-version') {
            Write-Verbose "Successfully connected to Netbox $($status.'netbox-version')"

            # Store version in module scope for later compatibility checks
            $script:NetboxVersion = $status.'netbox-version'
        }
        else {
            Write-Warning "Connected to API but received unexpected response format"
        }

        return $status
    }
    catch {
        # Re-throw with additional context
        $errorMessage = "Failed to verify Netbox API connectivity: $($_.Exception.Message)"
        throw [System.Exception]::new($errorMessage, $_.Exception)
    }
}
