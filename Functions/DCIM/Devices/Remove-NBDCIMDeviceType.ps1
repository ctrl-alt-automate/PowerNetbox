<#
.SYNOPSIS
    Removes a CIMDeviceType from Netbox D module.

.DESCRIPTION
    Removes a CIMDeviceType from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceType

    Returns all CIMDeviceType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMDeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
