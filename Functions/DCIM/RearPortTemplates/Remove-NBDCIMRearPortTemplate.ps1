<#
.SYNOPSIS
    Removes a CIMRearPortTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMRearPortTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRearPortTemplate

    Returns all CIMRearPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRearPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Rear Port Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete rear port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','rear-port-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
