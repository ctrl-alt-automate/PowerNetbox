function Test-NBDeprecatedParameter {
    <#
    .SYNOPSIS
        Checks if a deprecated parameter is being used and handles it appropriately.

    .DESCRIPTION
        This helper function checks if a deprecated parameter is being used and:
        - Emits a warning if the current Netbox version is >= the deprecation version
        - Returns $true if the parameter should be excluded from the API request
        - Returns $false if the parameter should still be sent (older Netbox version)

        This allows for graceful deprecation of parameters while maintaining
        backwards compatibility with older Netbox versions.

    .PARAMETER ParameterName
        The name of the deprecated parameter.

    .PARAMETER DeprecatedInVersion
        The Netbox version where this parameter was deprecated/removed.

    .PARAMETER BoundParameters
        The $PSBoundParameters from the calling function.

    .PARAMETER ReplacementMessage
        Optional message explaining what to use instead.

    .OUTPUTS
        [bool] - $true if parameter should be excluded, $false if it should be included

    .EXAMPLE
        # In a function with deprecated Is_Staff parameter:
        if (Test-NBDeprecatedParameter -ParameterName 'Is_Staff' -DeprecatedInVersion '4.5.0' -BoundParameters $PSBoundParameters) {
            $PSBoundParameters.Remove('Is_Staff') | Out-Null
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
        [string]$DeprecatedInVersion,

        [Parameter(Mandatory)]
        [hashtable]$BoundParameters,

        [string]$ReplacementMessage
    )

    # If the parameter wasn't used, nothing to do
    if (-not $BoundParameters.ContainsKey($ParameterName)) {
        return $false
    }

    # Get the current Netbox version
    $currentVersion = $script:NetboxConfig.ParsedVersion
    $deprecatedVersion = [version]$DeprecatedInVersion

    if ($null -eq $currentVersion) {
        Write-Verbose "Cannot determine Netbox version - parameter '$ParameterName' will be sent"
        return $false
    }

    if ($currentVersion -ge $deprecatedVersion) {
        # Parameter is deprecated in this version
        $warningMsg = "The '$ParameterName' parameter is deprecated in Netbox $DeprecatedInVersion and will be ignored."
        if ($ReplacementMessage) {
            $warningMsg += " $ReplacementMessage"
        }
        Write-Warning $warningMsg
        return $true  # Exclude from request
    }

    # Older version - parameter is still valid
    Write-Verbose "Parameter '$ParameterName' is valid for Netbox $currentVersion (deprecated in $DeprecatedInVersion)"
    return $false
}
