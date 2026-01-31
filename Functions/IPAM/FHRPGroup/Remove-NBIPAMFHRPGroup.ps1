<#
.SYNOPSIS
    Removes a PAMFHRPGroup from Netbox I module.

.DESCRIPTION
    Removes a PAMFHRPGroup from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMFHRPGroup

    Returns all PAMFHRPGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMFHRPGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM FHRP Group"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete FHRP group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-groups',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
