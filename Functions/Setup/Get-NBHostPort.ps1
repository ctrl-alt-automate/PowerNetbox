<#
.SYNOPSIS
    Retrieves the current port for Netbox API connections from Netbox Setup module.

.DESCRIPTION
    Retrieves the current port for Netbox API connections from Netbox Setup module.

.EXAMPLE
    Get-NBHostPort

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBHostPort {
    [CmdletBinding()]
    [OutputType([uint16])]
    param ()

    Write-Verbose "Getting Netbox host port"
    if ($null -eq $script:NetboxConfig.HostPort) {
        throw "Netbox host port is not set! You may set it with Set-NBHostPort -Port 443"
    }

    $script:NetboxConfig.HostPort
}