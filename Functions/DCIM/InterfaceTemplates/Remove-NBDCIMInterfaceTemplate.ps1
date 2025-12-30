<#
.SYNOPSIS
    Removes a DCIM Interface Template from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Interface Template from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Interface Template

    Returns all DCIM Interface Template objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMInterfaceTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Interface Te mp la te"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete interface template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','interface-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
