<#
.SYNOPSIS
    Tests whether the Netbox API connection is established.

.DESCRIPTION
    Tests whether the Netbox API connection is established.

.EXAMPLE
    Test-NBAPIConnected

    Returns $true if the API connection is established, $false otherwise.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Test-NBAPIConnected {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $script:NetboxConfig.Connected
}