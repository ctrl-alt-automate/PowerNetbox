<#
.SYNOPSIS
    Updates an existing IPAM FHRP GroupAssignment in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM FHRP GroupAssignment in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIIPAM FHRP GroupAssignment

    Returns all IPAM FHRP GroupAssignment objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIIPAM FHRP GroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Group,
        [string]$Interface_Type,
        [uint64]$Interface_Id,
        [uint16]$Priority,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating IPAM FHRP Group As si gn me nt"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-group-assignments',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
