function Get-NBHostname {
    [CmdletBinding()]
    param ()

    Write-Verbose "Getting Netbox hostname"
    if ($null -eq $script:NetboxConfig.Hostname) {
        throw "Netbox Hostname is not set! You may set it with Set-NBHostname -Hostname 'hostname.domain.tld'"
    }

    $script:NetboxConfig.Hostname
}