<#
.SYNOPSIS
    Updates an existing imeout in Netbox T module.

.DESCRIPTION
    Updates an existing imeout in Netbox T module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBTimeout

    Returns all imeout objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBTimeout {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([uint16])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [uint16]$TimeoutSeconds = 30
    )

    if ($PSCmdlet.ShouldProcess('Netbox Timeout', 'Set')) {
        $script:NetboxConfig.Timeout = $TimeoutSeconds
        $script:NetboxConfig.Timeout
    }
}