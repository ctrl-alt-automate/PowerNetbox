<#
.SYNOPSIS
    Retrieves the current API request timeout.

.DESCRIPTION
    Retrieves the current API request timeout.

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