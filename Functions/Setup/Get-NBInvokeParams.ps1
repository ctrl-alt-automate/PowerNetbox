<#
.SYNOPSIS
    Retrieves the current invoke parameters for Netbox API connections from Netbox Setup module.

.DESCRIPTION
    Retrieves the current invoke parameters for Netbox API connections from Netbox Setup module.

.EXAMPLE
    Get-NBInvokeParams

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBInvokeParams {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Params refers to a collection of invoke parameters')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()

    Write-Verbose "Getting Netbox InvokeParams"
    if ($null -eq $script:NetboxConfig.InvokeParams) {
        throw "Netbox Invoke Params is not set! You may set it with Set-NBInvokeParams -InvokeParams ..."
    }

    $script:NetboxConfig.InvokeParams
}