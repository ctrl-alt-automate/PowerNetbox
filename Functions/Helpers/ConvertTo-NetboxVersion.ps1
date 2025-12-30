function ConvertTo-NetboxVersion {
<#
.SYNOPSIS
    Parses Netbox version strings to [System.Version] objects.

.DESCRIPTION
    Extracts semantic version from Netbox version strings that may contain
    additional metadata (e.g., "4.2.9-Docker-3.2.1" -> "4.2.9").

    This is a central helper function used throughout the module to ensure
    consistent version parsing behavior.

.PARAMETER VersionString
    The raw version string from Netbox API (e.g., from Get-NBVersion).

.EXAMPLE
    ConvertTo-NetboxVersion -VersionString "4.4.8"
    # Returns: [version]"4.4.8"

.EXAMPLE
    ConvertTo-NetboxVersion -VersionString "4.2.9-Docker-3.2.1"
    # Returns: [version]"4.2.9"

.EXAMPLE
    ConvertTo-NetboxVersion -VersionString "v4.4.9-dev"
    # Returns: [version]"4.4.9"

.EXAMPLE
    "4.4.8" | ConvertTo-NetboxVersion
    # Pipeline support - Returns: [version]"4.4.8"

.OUTPUTS
    System.Version or $null if parsing fails

.NOTES
    Resolves issue #111: Version detection inconsistency
#>
    [CmdletBinding()]
    [OutputType([System.Version])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$VersionString
    )

    process {
        if ([string]::IsNullOrWhiteSpace($VersionString)) {
            Write-Verbose "Version string is null or empty"
            return $null
        }

        # Pattern: Major.Minor.Patch (Patch optional)
        # Handles: "4.4.8", "v4.4.8", "4.2.9-Docker-3.2.1", "4.4", "v4.4.9-dev"
        # Stops at first non-numeric/non-dot character after version numbers
        if ($VersionString -match '(\d+\.\d+(?:\.\d+)?)') {
            try {
                $version = [version]$Matches[1]
                Write-Verbose "Parsed version '$VersionString' as '$version'"
                return $version
            }
            catch {
                Write-Verbose "Failed to convert '$($Matches[1])' to version: $_"
                return $null
            }
        }

        Write-Verbose "Could not extract version from '$VersionString'"
        return $null
    }
}
