<#
.SYNOPSIS
    Removes a CIMConsoleServerPort from Netbox D module.

.DESCRIPTION
    Removes a CIMConsoleServerPort from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMConsoleServerPort

    Returns all CIMConsoleServerPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMConsoleServerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Console Server Port"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console server port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-server-ports',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
