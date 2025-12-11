<#
.SYNOPSIS
    Updates an existing ostName in Netbox H module.

.DESCRIPTION
    Updates an existing ostName in Netbox H module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBHostName

    Returns all ostName objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBHostName {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Hostname
    )

    if ($PSCmdlet.ShouldProcess('Netbox Hostname', 'Set')) {
        $script:NetboxConfig.Hostname = $Hostname.Trim()
        $script:NetboxConfig.Hostname
    }
}