<#
.SYNOPSIS
    Removes a CIMCable from Netbox D module.

.DESCRIPTION
    Removes a CIMCable from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMCable

    Returns all CIMCable objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Cable"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','cables',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
