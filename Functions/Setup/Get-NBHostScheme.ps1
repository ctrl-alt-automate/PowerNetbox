<#
.SYNOPSIS
    Retrieves Get-NBHost Scheme.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBHost Scheme.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBHostScheme

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBHostScheme {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox host scheme"
    if ($null -eq $script:NetboxConfig.Hostscheme) {
        throw "Netbox host sceme is not set! You may set it with Set-NBHostScheme -Scheme 'https'"
    }

    $script:NetboxConfig.HostScheme
}