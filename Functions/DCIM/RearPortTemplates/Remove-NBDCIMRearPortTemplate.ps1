<#
.SYNOPSIS
    Removes a DCIM Rear PortTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Rear PortTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Rear PortTemplate

    Returns all DCIM Rear PortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM Rear PortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Rear PortT em pl at e"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rear port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rear-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
