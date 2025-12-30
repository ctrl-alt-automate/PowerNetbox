<#
.SYNOPSIS
    Updates an existing ostPort in Netbox H module.

.DESCRIPTION
    Updates an existing ostPort in Netbox H module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBHostPort

    Returns all ostPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBHostPort {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint16]$Port
    )

    if ($PSCmdlet.ShouldProcess('Netbox Port', 'Set')) {
        $script:NetboxConfig.HostPort = $Port
        $script:NetboxConfig.HostPort
    }
}