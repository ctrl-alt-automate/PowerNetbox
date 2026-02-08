<#
.SYNOPSIS
    Retrieves the stored Netbox API credential.

.DESCRIPTION
    Retrieves the stored Netbox API credential.

.EXAMPLE
    Get-NBCredential

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCredential {
    [CmdletBinding()]
    [OutputType([pscredential])]
    param ()

    if (-not $script:NetboxConfig.Credential) {
        throw "Netbox Credentials not set! You may set with Set-NBCredential"
    }

    $script:NetboxConfig.Credential
}