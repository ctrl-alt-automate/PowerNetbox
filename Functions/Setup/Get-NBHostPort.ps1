<#
.SYNOPSIS
    Retrieves Get-NBHost Port.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBHost Port.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBHostPort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBHostPort {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox host port"
    if ($null -eq $script:NetboxConfig.HostPort) {
        throw "Netbox host port is not set! You may set it with Set-NBHostPort -Port 'https'"
    }

    $script:NetboxConfig.HostPort
}