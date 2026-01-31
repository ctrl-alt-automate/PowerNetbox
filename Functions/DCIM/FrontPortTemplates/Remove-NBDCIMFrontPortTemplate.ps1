<#
.SYNOPSIS
    Removes a CIMFrontPortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMFrontPortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMFrontPortTemplate

    Returns all CIMFrontPortTemplate objects.

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
        Write-Verbose "Removing DCIM Front Port Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','front-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
