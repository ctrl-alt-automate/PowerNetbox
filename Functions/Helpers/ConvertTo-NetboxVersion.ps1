function ConvertTo-NetboxVersion {
<#
.SYNOPSIS
    Parses Netbox version strings to [System.Version] objects.

.DESCRIPTION
    Extracts semantic version from Netbox version strings that may contain
    additional metadata (e.g., "4.2.9-Docker-3.2.1" -> "4.2.9").

    This is a central helper function ConvertTo-NetboxVersion {
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
