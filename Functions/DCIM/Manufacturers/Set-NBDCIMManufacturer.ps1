function Set-NBDCIMManufacturer {
<#
    .SYNOPSIS
        Update a manufacturer in Netbox

    .DESCRIPTION
        Updates an existing manufacturer object in Netbox.

    .PARAMETER Id
        The ID of the manufacturer to update

    .PARAMETER Name
        The name of the manufacturer

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Description
        A description of the manufacturer

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Force
        Skip confirmation prompts

    .EXAMPLE
        Set-NBDCIMManufacturer -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NBDCIMManufacturer -Name "Cisco" | Set-NBDCIMManufacturer -Description "Network equipment"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Force
    )

    process {
        foreach ($ManufacturerId in $Id) {
            $CurrentManufacturer = Get-NBDCIMManufacturer -Id $ManufacturerId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentManufacturer.Name)", "Update manufacturer")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $CurrentManufacturer.Id))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }
}
