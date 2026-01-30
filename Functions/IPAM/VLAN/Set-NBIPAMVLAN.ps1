<#
.SYNOPSIS
    Updates an existing PAMVLAN in Netbox I module.

.DESCRIPTION
    Updates an existing PAMVLAN in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMVLAN

    Returns all PAMVLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMVLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [ValidateRange(1, 4096)][uint16]$VID,
        [string]$Name,
        [string]$Status,
        [uint64]$Site,
        [uint64]$Group,
        [uint64]$Tenant,
        [uint64]$Role,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [uint64]$Owner,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating IPAM VLAN"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update VLAN')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
