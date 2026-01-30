<#
.SYNOPSIS
    Removes a PAMVLANGroup from Netbox I module.

.DESCRIPTION
    Removes a PAMVLANGroup from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMVLANGroup

    Returns all PAMVLANGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMVLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM VLANG ro up"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-groups',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
