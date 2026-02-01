<#
.SYNOPSIS
    Removes a DCIM ConsolePortTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM ConsolePortTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMConsolePortTemplate

    Returns all DCIM ConsolePortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMConsolePortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Console Port Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
