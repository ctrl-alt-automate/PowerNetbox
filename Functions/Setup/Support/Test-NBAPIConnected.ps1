<#
.SYNOPSIS
    Manages PIConnected in Netbox A module.

.DESCRIPTION
    Manages PIConnected in Netbox A module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Test-NBAPIConnected

    Returns all PIConnected objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Test-NBAPIConnected {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    $script:NetboxConfig.Connected
}