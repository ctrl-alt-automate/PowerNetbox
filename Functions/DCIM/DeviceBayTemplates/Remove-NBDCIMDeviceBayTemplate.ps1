<#
.SYNOPSIS
    Removes a CIMDeviceBayTemplate from Netbox D module.

.DESCRIPTION
    Removes a CIMDeviceBayTemplate from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceBayTemplate

    Returns all CIMDeviceBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMDeviceBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bay-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
