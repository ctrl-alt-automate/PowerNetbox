function Export-NBRackElevation {
<#
    .SYNOPSIS
        Export rack elevation visualization to HTML, Markdown, or SVG

    .DESCRIPTION
        Generates rack elevation visualizations in various formats:
        - HTML: Standalone HTML page with styled rack table
        - Markdown: GitHub-flavored markdown table
        - SVG: Native Netbox SVG rendering (passthrough)

        Supports pipeline input from Get-NBDCIMRack for batch exports.

    .PARAMETER Id
        The ID of the rack to export (required, pipeline support)

    .PARAMETER Format
        Output format: HTML (default), Markdown, SVG, or Console

    .PARAMETER Face
        Which face of the rack to show: Front (default), Rear, or Both

    .PARAMETER Path
        Output file path. If a directory, filename is auto-generated.
        If not specified, content is returned as string.

    .PARAMETER UseNativeRenderer
        Use Netbox's built-in SVG renderer instead of custom HTML/Markdown.
        Only applies to SVG and HTML formats.

    .PARAMETER IncludeEmptySlots
        Include all empty U positions in output. Default shows only occupied.

    .PARAMETER Compact
        For Console format: hide empty slots and show summary instead.

    .PARAMETER NoColor
        For Console format: disable ANSI color codes.

    .PARAMETER PassThru
        Return content as string instead of writing to file (even when -Path specified)

    .PARAMETER Force
        Overwrite existing files without confirmation

    .EXAMPLE
        Export-NBRackElevation -Id 24 -Format HTML -Path "./rack.html"

        Exports rack 24 as HTML file

    .EXAMPLE
        Export-NBRackElevation -Id 24 -Format Markdown

        Returns markdown table as string

    .EXAMPLE
        Get-NBDCIMRack -Site "Amsterdam" | Export-NBRackElevation -Format HTML -Path "./racks/"

        Exports all racks in Amsterdam site to HTML files

    .EXAMPLE
        Export-NBRackElevation -Id 24 -Format SVG -UseNativeRenderer -Path "./rack.svg"

        Saves native Netbox SVG rendering

    .EXAMPLE
        Export-NBRackElevation -Id 24 -Format Console

        Displays ASCII-art rack elevation in the terminal

    .EXAMPLE
        Export-NBRackElevation -Id 24 -Format Console -Compact -NoColor

        Compact console output without colors (for piping/logging)

    .LINK
        https://netbox.readthedocs.io/en/stable/models/dcim/rack/
#>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string], [void])]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [uint64]$Id,

        [ValidateSet('HTML', 'Markdown', 'SVG', 'Console')]
        [string]$Format = 'HTML',

        [ValidateSet('Front', 'Rear', 'Both')]
        [string]$Face = 'Front',

        [string]$Path,

        [switch]$UseNativeRenderer,

        [switch]$IncludeEmptySlots,

        [switch]$Compact,

        [switch]$NoColor,

        [switch]$PassThru,

        [switch]$Force
    )

    begin {
        # Validate parameters
        if ($Format -eq 'SVG' -and -not $UseNativeRenderer) {
            Write-Warning "SVG format requires -UseNativeRenderer. Enabling automatically."
            $UseNativeRenderer = $true
        }

        if ($UseNativeRenderer -and $Format -in @('Markdown', 'Console')) {
            Write-Warning "-UseNativeRenderer not applicable to $Format format. Ignoring."
            $UseNativeRenderer = $false
        }

        if ($Compact -and $Format -ne 'Console') {
            Write-Warning "-Compact only applies to Console format. Ignoring."
        }

        if ($NoColor -and $Format -ne 'Console') {
            Write-Warning "-NoColor only applies to Console format. Ignoring."
        }
    }

    process {
        Write-Verbose "Exporting rack elevation for rack ID $Id as $Format"

        # Get rack info for title
        $rack = Get-NBDCIMRack -Id $Id
        if (-not $rack) {
            Write-Error "Rack with ID $Id not found"
            return
        }

        $rackName = $rack.display
        $rackHeight = $rack.u_height
        $siteName = if ($rack.site) { $rack.site.display } else { 'Unknown Site' }

        # Determine faces to process
        $facesToProcess = switch ($Face) {
            'Both' { @('front', 'rear') }
            'Front' { @('front') }
            'Rear' { @('rear') }
        }

        $output = foreach ($currentFace in $facesToProcess) {
            $faceLabel = (Get-Culture).TextInfo.ToTitleCase($currentFace)

            if ($UseNativeRenderer -and $Format -in @('SVG', 'HTML')) {
                # Get native SVG from Netbox
                $svgContent = Get-NBDCIMRackElevation -Id $Id -Face $currentFace -Render svg

                if ($Format -eq 'SVG') {
                    $svgContent
                }
                else {
                    # HTML with embedded SVG
                    $htmlParams = @{
                        RackName   = $rackName
                        SiteName   = $siteName
                        UHeight    = $rackHeight
                        Face       = $faceLabel
                        SvgContent = $svgContent
                    }
                    ConvertTo-NBRackHTML @htmlParams
                }
            }
            else {
                # Get elevation data (use -All for automatic pagination)
                $elevation = Get-NBDCIMRackElevation -Id $Id -Face $currentFace -All

                # Filter to whole U positions only (remove half-U entries)
                $elevation = $elevation | Where-Object { $_.id -eq [Math]::Floor($_.id) }

                # Optionally filter to only occupied slots
                if (-not $IncludeEmptySlots) {
                    $elevation = $elevation | Where-Object { $_.device }
                }

                # Sort by U position (descending - top to bottom)
                $elevation = $elevation | Sort-Object -Property id -Descending

                switch ($Format) {
                    'HTML' {
                        $htmlParams = @{
                            RackName      = $rackName
                            SiteName      = $siteName
                            UHeight       = $rackHeight
                            Face          = $faceLabel
                            ElevationData = $elevation
                        }
                        ConvertTo-NBRackHTML @htmlParams
                    }
                    'Markdown' {
                        $mdParams = @{
                            RackName      = $rackName
                            SiteName      = $siteName
                            UHeight       = $rackHeight
                            Face          = $faceLabel
                            ElevationData = $elevation
                        }
                        ConvertTo-NBRackMarkdown @mdParams
                    }
                    'Console' {
                        $consoleParams = @{
                            RackName      = $rackName
                            SiteName      = $siteName
                            UHeight       = $rackHeight
                            Face          = $faceLabel
                            ElevationData = $elevation
                            Compact       = [bool]$Compact
                            NoColor       = [bool]$NoColor
                        }
                        ConvertTo-NBRackConsole @consoleParams
                    }
                }
            }
        }

        # Combine output for 'Both' faces
        if ($Face -eq 'Both' -and $Format -ne 'SVG') {
            if ($Format -eq 'Console') {
                # Console output is array of lines, flatten
                $output = $output | ForEach-Object { $_ }
            }
            else {
                $output = $output -join "`n`n"
            }
        }
        elseif ($output -is [array] -and $Format -ne 'Console') {
            $output = $output[0]
        }

        # Console format: join lines with newlines if returning as string
        if ($Format -eq 'Console' -and $output -is [array]) {
            $output = $output -join "`n"
        }

        # Handle output
        if ($Path) {
            # Determine output path
            $outputPath = $Path
            if (Test-Path $Path -PathType Container) {
                # It's a directory, generate filename
                $extension = switch ($Format) {
                    'HTML' { '.html' }
                    'Markdown' { '.md' }
                    'SVG' { '.svg' }
                    'Console' { '.txt' }
                }
                $safeName = $rackName -replace '[^\w\-]', '_'
                $outputPath = Join-Path $Path "$safeName$extension"
            }

            # Check if file exists
            if ((Test-Path $outputPath) -and -not $Force) {
                if (-not $PSCmdlet.ShouldProcess($outputPath, 'Overwrite existing file')) {
                    return
                }
            }

            Write-Verbose "Writing to $outputPath"
            $output | Out-File -FilePath $outputPath -Encoding utf8 -Force

            if ($PassThru) {
                $output
            }
            else {
                Write-Verbose "Exported rack elevation to: $outputPath"
            }
        }
        else {
            # Return content directly
            $output
        }
    }
}
