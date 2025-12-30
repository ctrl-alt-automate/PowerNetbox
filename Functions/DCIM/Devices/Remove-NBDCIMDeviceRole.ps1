<#
.SYNOPSIS
    Removes a DCIM Device Role from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Device Role from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Device Role

    Returns all DCIM Device Role objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM Device Role {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM DeviceR ol e"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-roles',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
