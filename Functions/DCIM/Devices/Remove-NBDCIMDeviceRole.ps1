<#
.SYNOPSIS
    Removes a CIMDeviceRole from Netbox D module.

.DESCRIPTION
    Removes a CIMDeviceRole from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceRole

    Returns all CIMDeviceRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMDeviceRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Device Role"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
