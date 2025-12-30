<#
.SYNOPSIS
    Removes a DCIM Front PortTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Front PortTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Front PortTemplate

    Returns all DCIM Front PortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMFrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Front Port Te mp la te"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','front-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
