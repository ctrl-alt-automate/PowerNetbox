<#
.SYNOPSIS
    Updates an existing virtual circuit termination in Netbox.

.DESCRIPTION
    Updates an existing virtual circuit termination in Netbox.

.PARAMETER Id
    The ID of the termination to update.

.PARAMETER Virtual_Circuit
    Virtual circuit ID.

.PARAMETER Interface
    Interface ID.

.PARAMETER Role
    Role (peer, hub, spoke).

.PARAMETER Description
    Description.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBVirtualCircuitTermination -Id 1 -Role "hub"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVirtualCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Virtual_Circuit,

        [uint64]$Interface,

        [ValidateSet('peer', 'hub', 'spoke')]
        [string]$Role,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-terminations', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Virtual Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
