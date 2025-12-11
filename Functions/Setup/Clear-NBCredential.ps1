<#
.SYNOPSIS
    Manages redential in Netbox C module.

.DESCRIPTION
    Manages redential in Netbox C module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Clear-NBCredential

    Returns all redential objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Clear-NBCredential {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$Force
    )

    if ($Force -or ($PSCmdlet.ShouldProcess('Netbox Credentials', 'Clear'))) {
        $script:NetboxConfig.Credential = $null
    }
}
