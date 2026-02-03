<#
.SYNOPSIS
    Removes a DCIM DeviceBayTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM DeviceBayTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMDeviceBayTemplate

    Deletes a DCIM DeviceBayTemplate object.

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
        Write-Verbose "Removing DCIM Device Bay Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-bay-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
