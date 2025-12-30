function Set-NBIPAMServiceTemplate {
<#
    .SYNOPSIS
        Update a service template in Netbox

    .DESCRIPTION
        Updates an existing service template object in Netbox.

    .PARAMETER Id
        The ID of the service template to update (required)

    .PARAMETER Name
        The name of the service template

    .PARAMETER Ports
        Array of port numbers

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp)

    .PARAMETER Description
        A description of the service template

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Set-NBIIPAM ServiceTemplate -Id 1 -Ports @(80, 443, 8080)

        Updates service template 1 with new ports
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating IPAM Service Te mp la te"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update service template')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
