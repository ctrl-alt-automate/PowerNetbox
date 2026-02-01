<#
.SYNOPSIS
    Removes a DCIM DeviceType from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM DeviceType from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM DeviceType

    Returns all DCIM DeviceType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM DeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Device Type"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
