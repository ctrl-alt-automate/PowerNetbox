<#
.SYNOPSIS
    Removes a IPAM RIR from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM RIR from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMRIR

    Deletes an IPAM RIR object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMRIR {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM RIR"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete RIR')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','rirs',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
