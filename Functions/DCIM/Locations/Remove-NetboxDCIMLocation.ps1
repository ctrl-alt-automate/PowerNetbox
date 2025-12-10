function Remove-NetboxDCIMLocation {
<#
    .SYNOPSIS
        Remove a location from Netbox

    .DESCRIPTION
        Deletes a location object from Netbox.

    .PARAMETER Id
        The ID of the location to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxDCIMLocation -Id 1

        Deletes location with ID 1

    .EXAMPLE
        Get-NetboxDCIMLocation -Name "Old Room" | Remove-NetboxDCIMLocation

        Deletes locations matching the name "Old Room"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete location')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
