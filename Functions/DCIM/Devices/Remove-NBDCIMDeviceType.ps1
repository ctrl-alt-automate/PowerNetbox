<#
.SYNOPSIS
    Removes a DCIM Device Type from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Device Type from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Device Type

    Returns all DCIM Device Type objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM Device Type {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM DeviceT yp e"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
