<#
.SYNOPSIS
    Removes a DCIM PowerFeed from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM PowerFeed from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM PowerFeed

    Returns all DCIM PowerFeed objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDDCIM PowerFeed {
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
