<#
.SYNOPSIS
    Removes a DCIM Console Port from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Console Port from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Console Port

    Returns all DCIM Console Port objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMConsolePort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Console Port"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete console port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','console-ports',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
