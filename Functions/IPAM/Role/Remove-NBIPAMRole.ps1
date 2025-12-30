<#
.SYNOPSIS
    Removes a IPAM Role from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM Role from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIIPAM Role

    Returns all IPAM Role objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIIPAM Role {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM Role"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete IPAM role')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'roles', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
