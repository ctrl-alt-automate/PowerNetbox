<#
.SYNOPSIS
    Retrieves Get-NBHostname.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBHostname.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBHostname

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBHostname {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox hostname"
    if ($null -eq $script:NetboxConfig.Hostname) {
        throw "Netbox Hostname is not set! You may set it with Set-NBHostname -Hostname 'hostname.domain.tld'"
    }

    $script:NetboxConfig.Hostname
}