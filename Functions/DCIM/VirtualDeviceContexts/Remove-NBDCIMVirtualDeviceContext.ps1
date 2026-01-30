<#
.SYNOPSIS
    Removes a CIMVirtualDeviceContext from Netbox D module.

.DESCRIPTION
    Removes a CIMVirtualDeviceContext from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMVirtualDeviceContext

    Returns all CIMVirtualDeviceContext objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMVirtualDeviceContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Virtual Device Context"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete virtual device context')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','virtual-device-contexts',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
