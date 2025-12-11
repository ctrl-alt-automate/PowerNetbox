<#
.SYNOPSIS
    Retrieves Get-NBInvoke Params.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBInvoke Params.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBInvokeParams

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBInvokeParams {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox InvokeParams"
    if ($null -eq $script:NetboxConfig.InvokeParams) {
        throw "Netbox Invoke Params is not set! You may set it with Set-NBInvokeParams -InvokeParams ..."
    }

    $script:NetboxConfig.InvokeParams
}