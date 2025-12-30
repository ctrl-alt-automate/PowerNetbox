<#
.SYNOPSIS
    Tests if the Netbox Branching plugin is available on the connected server.

.DESCRIPTION
    Checks if the netbox-branching plugin is installed and accessible on the
    connected Netbox instance by attempting to reach the branching API endpoint.

.PARAMETER Quiet
    Suppress warning messages and return only $true or $false.

.OUTPUTS
    [bool] Returns $true if the branching plugin is available, $false otherwise.

.EXAMPLE
    Test-NBBranchingAvailable
    Returns $true if branching is available.

.EXAMPLE
    if (Test-NBBranchingAvailable -Quiet) { Enter-NBBranch -Name "feature" }
    Check silently before using branching features.

.LINK
    https://github.com/netboxlabs/netbox-branching
#>
function Test-NBBranchingAvailable {
    Write-Verbose "Testing Branching Available"
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [switch]$Quiet
    )

    CheckNetboxIsConnected

    try {
        $Segments = [System.Collections.ArrayList]::new(@('plugins', 'netbox-branching', 'branches'))
        $URI = BuildNewURI -Segments $Segments -Parameters @{ limit = 1 }

        $null = InvokeNetboxRequest -URI $URI -Method GET -Raw
        return $true
    }
    catch {
        if (-not $Quiet) {
            Write-Warning "Netbox Branching plugin is not available: $($_.Exception.Message)"
        }
        return $false
    }
}
