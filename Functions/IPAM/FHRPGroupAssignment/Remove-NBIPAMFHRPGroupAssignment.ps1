<#
.SYNOPSIS
    Removes a PAMFHRPGroupAssignment from Netbox I module.

.DESCRIPTION
    Removes a PAMFHRPGroupAssignment from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMFHRPGroupAssignment

    Returns all PAMFHRPGroupAssignment objects.

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
        Write-Verbose "Removing IPA MF HR PG ro up As si gn me nt"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-group-assignments',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
