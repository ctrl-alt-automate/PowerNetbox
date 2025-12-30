<#
.SYNOPSIS
    Removes a DCIM Virtual Chassis from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Virtual Chassis from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Virtual Chassis

    Returns all DCIM Virtual Chassis objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMVirtualChassis {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Virtual Chassis"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete virtual chassis')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','virtual-chassis',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
