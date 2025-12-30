function New-NBDCIMManufacturer {
<#
    .SYNOPSIS
        Create a new manufacturer in Netbox

    .DESCRIPTION
        Creates a new manufacturer object in Netbox.

    .PARAMETER Name
        The name of the manufacturer (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER Description
        A description of the manufacturer

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NBDDCIM Manufacturer -Name "Cisco" -Slug "cisco"

        Creates a new manufacturer named "Cisco"

    .EXAMPLE
        New-NBDDCIM Manufacturer -Name "Dell Technologies" -Slug "dell" -Description "Server and storage manufacturer"

        Creates a new manufacturer with description
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Slug,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating DCIM Manufacturer"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new manufacturer')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
