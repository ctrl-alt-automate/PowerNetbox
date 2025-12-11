function Get-NBHostPort {
    [CmdletBinding()]
    param ()

    Write-Verbose "Getting Netbox host port"
    if ($null -eq $script:NetboxConfig.HostPort) {
        throw "Netbox host port is not set! You may set it with Set-NBHostPort -Port 'https'"
    }

    $script:NetboxConfig.HostPort
}