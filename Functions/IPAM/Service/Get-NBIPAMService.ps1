function Get-NBIPAMService {
<#
    .SYNOPSIS
        Get services from Netbox

    .DESCRIPTION
        Retrieves service objects from Netbox with optional filtering.
        Services represent network services running on devices or virtual machines.

    .PARAMETER Id
        The ID of the service to retrieve

    .PARAMETER Name
        Filter by service name

    .PARAMETER Query
        A general search query

    .PARAMETER Protocol
        Filter by protocol (tcp, udp, sctp)

    .PARAMETER Port
        Filter by port number

    .PARAMETER Device_Id
        Filter by device ID

    .PARAMETER Virtual_Machine_Id
        Filter by virtual machine ID

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NBIPAMService

        Returns all services

    .EXAMPLE
        Get-NBIPAMService -Protocol tcp -Port 443

        Returns TCP services on port 443
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Port,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Device_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Virtual_Machine_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving IPAM Service"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($ServiceId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services', $ServiceId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
