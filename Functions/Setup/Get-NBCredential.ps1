<#
.SYNOPSIS
    Retrieves Get-NBCredential.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBCredential.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBCredential

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCredential {
    Write-Verbose "Retrieving Credential"
    [CmdletBinding()]
    [OutputType([pscredential])]
    param ()

    if (-not $script:NetboxConfig.Credential) {
        throw "Netbox Credentials not set! You may set with Set-NBCredential"
    }

    $script:NetboxConfig.Credential
}