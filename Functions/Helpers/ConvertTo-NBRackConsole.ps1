function ConvertTo-NBRackConsole {
<#
    .SYNOPSIS
        Convert rack elevation data to ASCII-art console output

    .DESCRIPTION
        Internal helper function that generates an ASCII-art representation
        of a rack elevation diagram for terminal/console display.

    .PARAMETER RackName
        Display name of the rack

    .PARAMETER SiteName
        Display name of the site

    .PARAMETER UHeight
        Total height of the rack in U

    .PARAMETER Face
        Face being displayed (Front or Rear)

    .PARAMETER ElevationData
        Array of elevation unit objects from Get-NBDCIMRackElevation

    .PARAMETER Compact
        Hide empty slots, show only occupied units

    .PARAMETER NoColor
        Disable ANSI color codes for terminals that don't support them

    .EXAMPLE
        $elevation = Get-NBDCIMRackElevation -Id 24
        ConvertTo-NBRackConsole -RackName "DC1-R01" -SiteName "Amsterdam" -UHeight 42 -Face Front -ElevationData $elevation

        Generates ASCII-art rack elevation for display in terminal with ANSI colors.

    .EXAMPLE
        $elevation = Get-NBDCIMRackElevation -Id 24
        ConvertTo-NBRackConsole -RackName "DC1-R01" -SiteName "Amsterdam" -UHeight 42 -Face Front -ElevationData $elevation -Compact

        Generates compact output hiding empty slots and showing summary counts.

    .EXAMPLE
        $elevation = Get-NBDCIMRackElevation -Id 24
        ConvertTo-NBRackConsole -RackName "DC1-R01" -SiteName "Amsterdam" -UHeight 42 -Face Front -ElevationData $elevation -NoColor | Out-File rack.txt

        Generates plain text output without ANSI colors for file logging or piping.

    .NOTES
        This is an internal helper function. Use Export-NBRackElevation -Format Console for the public interface.
#>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$RackName,

        [string]$SiteName = '',

        [int]$UHeight = 42,

        [string]$Face = 'Front',

        [PSCustomObject[]]$ElevationData,

        [switch]$Compact,

        [switch]$NoColor
    )

    # ANSI color codes (if colors enabled)
    # Note: Use [char]27 instead of `e for PS 5.1 compatibility
    $esc = [char]27
    $colors = @{
        Reset   = if ($NoColor) { '' } else { "$esc[0m" }
        Bold    = if ($NoColor) { '' } else { "$esc[1m" }
        Dim     = if ($NoColor) { '' } else { "$esc[2m" }
        Blue    = if ($NoColor) { '' } else { "$esc[34m" }
        Cyan    = if ($NoColor) { '' } else { "$esc[36m" }
        Green   = if ($NoColor) { '' } else { "$esc[32m" }
        Yellow  = if ($NoColor) { '' } else { "$esc[33m" }
        BgBlue  = if ($NoColor) { '' } else { "$esc[44m" }
        White   = if ($NoColor) { '' } else { "$esc[37m" }
    }

    # Box drawing characters (as strings for multiplication)
    $box = @{
        TopLeft     = [string][char]0x2554  # ╔
        TopRight    = [string][char]0x2557  # ╗
        BottomLeft  = [string][char]0x255A  # ╚
        BottomRight = [string][char]0x255D  # ╝
        Horizontal  = [string][char]0x2550  # ═
        Vertical    = [string][char]0x2551  # ║
        TeeDown     = [string][char]0x2566  # ╦
        TeeUp       = [string][char]0x2569  # ╩
        TeeRight    = [string][char]0x2560  # ╠
        TeeLeft     = [string][char]0x2563  # ╣
        Cross       = [string][char]0x256C  # ╬
    }

    # Dimensions
    $uNumWidth = 4
    $deviceWidth = 50
    $totalWidth = $uNumWidth + $deviceWidth + 5  # borders and spacing

    $output = [System.Collections.ArrayList]::new()

    # Create a lookup of devices by position
    $deviceLookup = @{}
    foreach ($unit in $ElevationData) {
        if ($unit.device) {
            $deviceLookup[[int]$unit.id] = $unit
        }
    }

    # Header
    $title = "$RackName - $Face Face"
    $subtitle = "Site: $SiteName | Height: ${UHeight}U"

    # Top border
    [void]$output.Add("$($colors.Cyan)$($box.TopLeft)$($box.Horizontal * ($totalWidth - 2))$($box.TopRight)$($colors.Reset)")

    # Title
    $paddedTitle = $title.PadLeft(([int](($totalWidth - 2 + $title.Length) / 2))).PadRight($totalWidth - 2)
    [void]$output.Add("$($colors.Cyan)$($box.Vertical)$($colors.Reset)$($colors.Bold)  $paddedTitle$($colors.Reset)$($colors.Cyan)$($box.Vertical)$($colors.Reset)")

    # Subtitle
    $paddedSubtitle = $subtitle.PadLeft(([int](($totalWidth - 2 + $subtitle.Length) / 2))).PadRight($totalWidth - 2)
    [void]$output.Add("$($colors.Cyan)$($box.Vertical)$($colors.Reset)$($colors.Dim)  $paddedSubtitle$($colors.Reset)$($colors.Cyan)$($box.Vertical)$($colors.Reset)")

    # Divider
    [void]$output.Add("$($colors.Cyan)$($box.TeeRight)$($box.Horizontal * $uNumWidth)$($box.TeeDown)$($box.Horizontal * ($totalWidth - $uNumWidth - 3))$($box.TeeLeft)$($colors.Reset)")

    # Track consecutive empty slots for compact mode
    $emptyCount = 0
    $lastWasEmpty = $false

    # Generate rows from top to bottom
    for ($u = $UHeight; $u -ge 1; $u--) {
        $unit = $deviceLookup[$u]
        $hasDevice = $unit -and $unit.device

        if ($Compact -and -not $hasDevice) {
            $emptyCount++
            $lastWasEmpty = $true
            continue
        }

        # If we were in compact mode and had empty slots, show summary
        if ($Compact -and $lastWasEmpty -and $emptyCount -gt 0) {
            $emptyText = "... ($emptyCount empty slots) ..."
            $paddedEmpty = $emptyText.PadRight($deviceWidth)
            [void]$output.Add("$($colors.Cyan)$($box.Vertical)$($colors.Reset)$($colors.Dim)    $($box.Vertical) $paddedEmpty$($colors.Reset)$($colors.Cyan)$($box.Vertical)$($colors.Reset)")
            $emptyCount = 0
            $lastWasEmpty = $false
        }

        $uNum = $u.ToString().PadLeft(3)

        if ($hasDevice) {
            $deviceName = $unit.device.display
            if ($deviceName.Length -gt $deviceWidth - 2) {
                $deviceName = $deviceName.Substring(0, $deviceWidth - 5) + "..."
            }

            # Create a device bar
            $bar = "$($colors.BgBlue)$($colors.White) $deviceName $($colors.Reset)"
            $padding = ' ' * ($deviceWidth - $deviceName.Length - 2)

            [void]$output.Add("$($colors.Cyan)$($box.Vertical)$($colors.Reset)$($colors.Bold) $uNum $($colors.Cyan)$($box.Vertical)$($colors.Reset) $bar$padding$($colors.Cyan)$($box.Vertical)$($colors.Reset)")
        }
        else {
            $emptySlot = ' ' * $deviceWidth
            [void]$output.Add("$($colors.Cyan)$($box.Vertical)$($colors.Reset)$($colors.Dim) $uNum $($colors.Cyan)$($box.Vertical)$($colors.Reset)$emptySlot$($colors.Cyan)$($box.Vertical)$($colors.Reset)")
        }
    }

    # If compact mode and ended with empty slots
    if ($Compact -and $emptyCount -gt 0) {
        $emptyText = "... ($emptyCount empty slots) ..."
        $paddedEmpty = $emptyText.PadRight($deviceWidth)
        [void]$output.Add("$($colors.Cyan)$($box.Vertical)$($colors.Reset)$($colors.Dim)    $($box.Vertical) $paddedEmpty$($colors.Reset)$($colors.Cyan)$($box.Vertical)$($colors.Reset)")
    }

    # Bottom border
    [void]$output.Add("$($colors.Cyan)$($box.BottomLeft)$($box.Horizontal * $uNumWidth)$($box.TeeUp)$($box.Horizontal * ($totalWidth - $uNumWidth - 3))$($box.BottomRight)$($colors.Reset)")

    # Footer
    $footer = "Generated by PowerNetbox | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    [void]$output.Add("$($colors.Dim)$footer$($colors.Reset)")

    return $output.ToArray()
}
