<#
.SYNOPSIS
    Sets the credential for Netbox API authentication.

.DESCRIPTION
    Sets the credential for Netbox API authentication.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBCredential

    Returns all redential objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBCredential {
    [CmdletBinding(DefaultParameterSetName = 'CredsObject',
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscredential])]
    param
    (
        [Parameter(ParameterSetName = 'CredsObject',
            Mandatory = $true)]
        [pscredential]$Credential,

        [Parameter(ParameterSetName = 'UserPass',
            Mandatory = $true)]
        [securestring]$Token
    )

    if ($PSCmdlet.ShouldProcess('Netbox Credentials', 'Set')) {
        switch ($PsCmdlet.ParameterSetName) {
            'CredsObject' {
                $script:NetboxConfig.Credential = $Credential
                break
            }

            'UserPass' {
                $script:NetboxConfig.Credential = [System.Management.Automation.PSCredential]::new('notapplicable', $Token)
                break
            }
        }

        $script:NetboxConfig.Credential
    }
}