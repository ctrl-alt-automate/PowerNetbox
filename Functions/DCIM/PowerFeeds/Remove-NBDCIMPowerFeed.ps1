<#
.SYNOPSIS
    Removes a CIMPowerFeed from Netbox D module.

.DESCRIPTION
    Removes a CIMPowerFeed from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMPowerFeed

    Returns all CIMPowerFeed objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Power Feed"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-feeds',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
