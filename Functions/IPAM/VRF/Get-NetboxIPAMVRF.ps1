function Get-NetboxIPAMVRF {
<#
    .SYNOPSIS
        Get VRFs from Netbox

    .DESCRIPTION
        Retrieves VRF (Virtual Routing and Forwarding) objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the VRF to retrieve

    .PARAMETER Name
        Filter by VRF name

    .PARAMETER Query
        A general search query

    .PARAMETER RD
        Filter by route distinguisher

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Tenant
        Filter by tenant name

    .PARAMETER Enforce_Unique
        Filter by enforce unique flag

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NetboxIPAMVRF

        Returns all VRFs

    .EXAMPLE
        Get-NetboxIPAMVRF -Name "Production"

        Returns VRFs matching the name "Production"

    .EXAMPLE
        Get-NetboxIPAMVRF -RD "65001:100"

        Returns VRFs with the specified route distinguisher
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$RD,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Enforce_Unique,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($VRFId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs', $VRFId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}
