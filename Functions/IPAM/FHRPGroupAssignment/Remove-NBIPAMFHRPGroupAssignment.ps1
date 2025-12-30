<#
.SYNOPSIS
    Removes a IPAM FHRP GroupAssignment from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM FHRP GroupAssignment from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIIPAM FHRP GroupAssignment

    Returns all IPAM FHRP GroupAssignment objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM FHRP Group As si gn me nt"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-group-assignments',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
