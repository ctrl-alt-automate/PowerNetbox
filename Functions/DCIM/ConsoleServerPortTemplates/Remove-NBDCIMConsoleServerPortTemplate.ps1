<#
.SYNOPSIS
    Removes a CIMConsoleServerPortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMConsoleServerPortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMConsoleServerPortTemplate

    Returns all CIMConsoleServerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMConsoleServerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing D CI MC on so le Se rv er Po rt Te mp la te"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console server port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-server-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
