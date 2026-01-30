<#
.SYNOPSIS
    Removes a PAMAggregate from Netbox I module.

.DESCRIPTION
    Removes a PAMAggregate from Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBIPAMAggregate

    Returns all PAMAggregate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBIPAMAggregate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM Aggregate"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete aggregate')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
