<#
.SYNOPSIS
    Removes a PAMVLAN from Netbox I module.

.DESCRIPTION
    Removes a PAMVLAN from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMVLAN

    Returns all PAMVLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMVLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPA MV LA N"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
