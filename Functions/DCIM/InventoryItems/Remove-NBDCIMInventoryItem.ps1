<#
.SYNOPSIS
    Removes a CIMInventoryItem from Netbox D module.

.DESCRIPTION
    Removes a CIMInventoryItem from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMInventoryItem

    Returns all CIMInventoryItem objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMInventoryItem {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing D CI MI nv en to ry It em"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-items',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
