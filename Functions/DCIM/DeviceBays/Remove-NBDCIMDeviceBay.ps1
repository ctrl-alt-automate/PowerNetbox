<#
.SYNOPSIS
    Removes a DCIM Device Bay from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Device Bay from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Device Bay

    Returns all DCIM Device Bay objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMDeviceBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM DeviceB ay"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bays',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
