function Set-NBIPAMRouteTarget {
<#
    .SYNOPSIS
        Update a route target in Netbox

    .DESCRIPTION
        Updates an existing route target object in Netbox.

    .PARAMETER Id
        The ID of the route target to update (required)

    .PARAMETER Name
        The route target value (RFC 4360 format)

    .PARAMETER Tenant
        The tenant ID that owns this route target

    .PARAMETER Description
        A description of the route target

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NBIPAMRouteTarget -Id 1 -Description "Updated description"

        Updates the description of route target 1

    .EXAMPLE
        Set-NBIPAMRouteTarget -Id 1 -Tenant 5

        Assigns route target 1 to tenant 5
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update route target')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
