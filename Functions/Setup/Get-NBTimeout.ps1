<#
.SYNOPSIS
    Retrieves Get-NBTimeout.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBTimeout.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBTimeout

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBTimeout {
    [CmdletBinding()]
    [OutputType([uint16])]
    param ()

    Write-Verbose "Getting Netbox Timeout"
    if ($null -eq $script:NetboxConfig.Timeout) {
        throw "Netbox Timeout is not set! You may set it with Set-NBTimeout -TimeoutSeconds [uint16]"
    }

    $script:NetboxConfig.Timeout
}