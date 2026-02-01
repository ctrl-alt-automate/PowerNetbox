<#
.SYNOPSIS
    Removes a DCIM Module from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Module from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMModule

    Returns all DCIM Module objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Module"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','modules',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
