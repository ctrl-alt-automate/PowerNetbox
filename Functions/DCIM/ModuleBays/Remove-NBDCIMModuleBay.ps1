<#
.SYNOPSIS
    Removes a DCIM Module Bay from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Module Bay from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Module Bay

    Returns all DCIM Module Bay objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM Module Bay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM ModuleB ay"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','module-bays',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
