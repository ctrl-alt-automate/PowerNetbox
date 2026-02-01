<#
.SYNOPSIS
    Removes a DCIM FrontPortTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM FrontPortTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM FrontPortTemplate

    Returns all DCIM FrontPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM FrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Front Port Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','front-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
