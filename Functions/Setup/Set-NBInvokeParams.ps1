<#
.SYNOPSIS
    Updates an existing nvokeParams in Netbox I module.

.DESCRIPTION
    Updates an existing nvokeParams in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBInvokeParams

    Returns all nvokeParams objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBInvokeParams {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Params refers to a collection of invoke parameters')]
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [array]$InvokeParams
    )

    if ($PSCmdlet.ShouldProcess('Netbox Invoke Params', 'Set')) {
        $script:NetboxConfig.InvokeParams = $InvokeParams
        $script:NetboxConfig.InvokeParams
    }
}