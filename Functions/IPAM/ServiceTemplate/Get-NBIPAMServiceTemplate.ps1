function Get-NBIPAMServiceTemplate {
<#
    .SYNOPSIS
        Get service templates from Netbox

    .DESCRIPTION
        Retrieves service template objects from Netbox with optional filtering.
        Service templates are reusable definitions for creating services.

    .PARAMETER Id
        The ID of the service template to retrieve

    .PARAMETER Name
        Filter by template name

    .PARAMETER Query
        A general search query

    .PARAMETER Protocol
        Filter by protocol (tcp, udp, sctp)

    .PARAMETER Port
        Filter by port number

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NBIPAMServiceTemplate

        Returns all service templates

    .EXAMPLE
        Get-NBIPAMServiceTemplate -Name "HTTP"

        Returns service templates matching the name "HTTP"
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

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving IPAM Service Template"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($TemplateId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates', $TemplateId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
