function Get-NBDCIMRackElevation {
<#
    .SYNOPSIS
        Get rack elevation data from Netbox

    .DESCRIPTION
        Retrieves rack elevation data showing which devices occupy which rack units.
        Supports both JSON data output and native SVG rendering from Netbox.

    .PARAMETER Id
        The ID of the rack to retrieve elevation for (required)

    .PARAMETER Face
        Which face of the rack to show: front (default) or rear

    .PARAMETER Render
        Output format: json (default) returns structured data, svg returns Netbox-rendered SVG image

    .PARAMETER IncludeImages
        Include device images in SVG output (only applies when -Render svg)

    .PARAMETER Limit
        Limit the number of rack units returned (for pagination)

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER All
        Automatically paginate through all results. Cannot be used with Limit or Offset.

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Get-NBDCIMRackElevation -Id 24

        Returns elevation data for rack ID 24 (front face, JSON format)

    .EXAMPLE
        Get-NBDCIMRackElevation -Id 24 -Face rear

        Returns elevation data for the rear face of rack ID 24

    .EXAMPLE
        Get-NBDCIMRackElevation -Id 24 -Render svg

        Returns the native Netbox SVG rendering of the rack elevation

    .EXAMPLE
        Get-NBDCIMRack -Name "Amsterdam-R01" | Get-NBDCIMRackElevation

        Pipeline support: get elevation for rack by name

    .EXAMPLE
        Get-NBDCIMRackElevation -Id 24 | Where-Object { $_.device }

        Get only occupied rack units

    .EXAMPLE
        Get-NBDCIMRackElevation -Id 24 -All

        Get all rack units without manual pagination

    .LINK
        https://netbox.readthedocs.io/en/stable/models/dcim/rack/
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject], [string])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [uint64[]]$Id,

        [ValidateSet('front', 'rear')]
        [string]$Face = 'front',

        [ValidateSet('json', 'svg')]
        [string]$Render = 'json',

        [switch]$IncludeImages,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [uint16]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving DCIM Rack Elevation for rack ID $Id"

        # Build URI segments: /api/dcim/racks/{id}/elevation/
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks', $Id, 'elevation'))

        # Build query parameters
        $Parameters = @{}

        if ($Face -ne 'front') {
            $Parameters['face'] = $Face
        }

        if ($Render -eq 'svg') {
            $Parameters['render'] = 'svg'
        }

        if ($IncludeImages -and $Render -eq 'svg') {
            $Parameters['include_images'] = 'true'
        }

        if ($PSBoundParameters.ContainsKey('Limit')) {
            $Parameters['limit'] = $Limit
        }

        if ($PSBoundParameters.ContainsKey('Offset')) {
            $Parameters['offset'] = $Offset
        }

        $URI = BuildNewURI -Segments $Segments -Parameters $Parameters

        if ($Render -eq 'svg') {
            # SVG rendering returns raw text, not JSON
            # Use Invoke-WebRequest directly to get raw SVG string (Invoke-RestMethod parses as XML)
            Write-Verbose "Requesting SVG rendering from Netbox"

            # Get authorization and branch context headers using centralized helper
            $headers = Get-NBRequestHeaders

            $invokeParams = Get-NBInvokeParams
            $splat = @{
                'Uri'         = $URI.Uri.AbsoluteUri
                'Headers'     = $headers
                'Method'      = 'GET'
                'ErrorAction' = 'Stop'
            }
            $splat += $invokeParams

            try {
                $response = Invoke-WebRequest @splat
                # Return the raw SVG content as string
                $response.Content
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
        else {
            # JSON mode - use centralized pagination
            InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
        }
    }
}
