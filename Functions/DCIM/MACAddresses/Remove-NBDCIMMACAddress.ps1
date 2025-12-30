<#
.SYNOPSIS
    Removes a CIMMACAddress from Netbox D module.

.DESCRIPTION
    Removes a CIMMACAddress from Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMMACAddress

    Returns all CIMMACAddress objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMMACAddress {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing D CI MM AC Ad dr es s"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete MAC address')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','mac-addresses',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
