function Get-NBInvokeParams {
    [CmdletBinding()]
    param ()

    Write-Verbose "Getting Netbox InvokeParams"
    if ($null -eq $script:NetboxConfig.InvokeParams) {
        throw "Netbox Invoke Params is not set! You may set it with Set-NBInvokeParams -InvokeParams ..."
    }

    $script:NetboxConfig.InvokeParams
}