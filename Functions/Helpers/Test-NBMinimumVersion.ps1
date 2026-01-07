function Test-NBMinimumVersion {
    <#
    .SYNOPSIS
        Checks if the connected Netbox version meets the minimum requirement.

    .DESCRIPTION
        This helper function checks if a parameter requires a minimum Netbox version
        and handles it appropriately:
        - Emits a warning if the current Netbox version is < the required version
        - Returns $true if the parameter should be excluded from the API request
        - Returns $false if the parameter can be used (version meets requirement)

        This allows for graceful handling of new features that only work on newer
        Netbox versions while maintaining backwards compatibility.

    .PARAMETER ParameterName
        The name of the parameter that requires a minimum version.

    .PARAMETER MinimumVersion
        The minimum Netbox version required for this parameter.

    .PARAMETER BoundParameters
        The $PSBoundParameters from the calling function.

    .PARAMETER FeatureName
        Optional friendly name for the feature (used in warning message).

    .OUTPUTS
        [bool] - $true if parameter should be excluded (version too low), $false if it can be used

    .EXAMPLE
        # In a function with a Profile parameter that requires Netbox 4.5+:
        if (Test-NBMinimumVersion -ParameterName 'Profile' -MinimumVersion '4.5.0' -BoundParameters $PSBoundParameters) {
            # Version too low - parameter will be excluded
        }

    .NOTES
        This function requires that Connect-NBAPI has been called and
        $script:NetboxConfig.ParsedVersion is set.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]$ParameterName,

        [Parameter(Mandatory)]
        [string]$MinimumVersion,

        [Parameter(Mandatory)]
        [hashtable]$BoundParameters,

        [string]$FeatureName
    )

    # If the parameter wasn't used, nothing to do
    if (-not $BoundParameters.ContainsKey($ParameterName)) {
        return $false
    }

    # Get the current Netbox version
    $currentVersion = $script:NetboxConfig.ParsedVersion
    $requiredVersion = [version]$MinimumVersion

    if ($null -eq $currentVersion) {
        Write-Verbose "Cannot determine Netbox version - parameter '$ParameterName' will be sent"
        return $false
    }

    if ($currentVersion -lt $requiredVersion) {
        # Version is too low for this feature
        $feature = if ($FeatureName) { $FeatureName } else { "The '$ParameterName' parameter" }
        Write-Warning "$feature requires Netbox $MinimumVersion or higher (connected to $currentVersion). Parameter will be ignored."
        return $true  # Exclude from request
    }

    # Version meets requirement
    Write-Verbose "Parameter '$ParameterName' is valid for Netbox $currentVersion (requires $MinimumVersion)"
    return $false
}
