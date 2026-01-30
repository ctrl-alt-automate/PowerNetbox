function Remove-NBDCIMLocation {
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
        Remove-NBDCIMLocation -Id 1

        Deletes location with ID 1

    .EXAMPLE
        Get-NBDCIMLocation -Name "Old Room" | Remove-NBDCIMLocation

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
        Write-Verbose "Removing DCIM Location"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete location')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
