<#
.SYNOPSIS
    Retrieves the current HTTP scheme for Netbox API connections from Netbox Setup module.

.DESCRIPTION
    Retrieves the current HTTP scheme for Netbox API connections from Netbox Setup module.

.EXAMPLE
    Get-NBHostScheme

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBHostScheme {
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    Write-Verbose "Getting Netbox host scheme"
    if ($null -eq $script:NetboxConfig.HostScheme) {
        throw "Netbox host scheme is not set! You may set it with Set-NBHostScheme -Scheme 'https'"
    }

    $script:NetboxConfig.HostScheme
}