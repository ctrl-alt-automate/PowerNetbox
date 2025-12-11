<#
.SYNOPSIS
    Removes a CIMDeviceBay from Netbox D module.

.DESCRIPTION
    Removes a CIMDeviceBay from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceBay

    Returns all CIMDeviceBay objects.

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
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bays',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
