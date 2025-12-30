<#
.SYNOPSIS
    Removes a CIMPlatform from Netbox D module.

.DESCRIPTION
    Removes a CIMPlatform from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPlatform

    Returns all CIMPlatform objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPlatform {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing D CI MP la tf or m"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete platform')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','platforms',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
