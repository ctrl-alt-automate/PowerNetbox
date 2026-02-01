<#
.SYNOPSIS
    Sets the HTTP scheme (http/https) for Netbox API connections.

.DESCRIPTION
    Sets the HTTP scheme (http/https) for Netbox API connections.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBHostScheme

    Returns all ostScheme objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBHostScheme {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('https', 'http', IgnoreCase = $true)]
        [string]$Scheme = 'https'
    )

    if ($PSCmdlet.ShouldProcess('Netbox Host Scheme', 'Set')) {
        if ($Scheme -eq 'http') {
            Write-Warning "Connecting via non-secure HTTP is not-recommended"
        }

        $script:NetboxConfig.HostScheme = $Scheme
        $script:NetboxConfig.HostScheme
    }
}