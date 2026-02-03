<#
.SYNOPSIS
    Sets the port for Netbox API connections.

.DESCRIPTION
    Sets the port for Netbox API connections.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBHostPort

    Sets the Netbox API host port.

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