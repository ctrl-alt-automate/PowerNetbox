<#
.SYNOPSIS
    Removes a CIMInterfaceTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMInterfaceTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInterfaceTemplate

    Returns all CIMInterfaceTemplate objects.

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
        Write-Verbose "Removing DCIM Interface Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete interface template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','interface-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
