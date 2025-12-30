function Remove-NBDDCIM Rack {
<#
    .SYNOPSIS
        Delete a rack from Netbox

    .DESCRIPTION
        Removes a rack object from Netbox.

    .PARAMETER Id
        The ID of the rack to delete

    .PARAMETER Force
        Skip confirmation prompts

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NBDDCIM Rack -Id 1

        Deletes rack with ID 1 (with confirmation)

    .EXAMPLE
        Remove-NBDDCIM Rack -Id 1 -Confirm:$false

        Deletes rack with ID 1 without confirmation

    .EXAMPLE
        Get-NBDDCIM Rack -Name "Rack-01" | Remove-NBDDCIM Rack

        Deletes rack named "Rack-01"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing DCIM Rack"
        foreach ($RackId in $Id) {
            $CurrentRack = Get-NBDDCIM Rack -Id $RackId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentRack.Name)", "Delete rack")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks', $CurrentRack.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
