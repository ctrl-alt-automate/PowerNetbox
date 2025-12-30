function Remove-NBDCIMManufacturer {
<#
    .SYNOPSIS
        Delete a manufacturer from Netbox

    .DESCRIPTION
        Removes a manufacturer object from Netbox.

    .PARAMETER Id
        The ID of the manufacturer to delete

    .PARAMETER Force
        Skip confirmation prompts

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NBDDCIM Manufacturer -Id 1

        Deletes manufacturer with ID 1 (with confirmation)

    .EXAMPLE
        Remove-NBDDCIM Manufacturer -Id 1 -Confirm:$false

        Deletes manufacturer with ID 1 without confirmation

    .EXAMPLE
        Get-NBDDCIM Manufacturer -Name "OldVendor" | Remove-NBDDCIM Manufacturer

        Deletes manufacturer named "OldVendor"
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
        Write-Verbose "Removing DCIM Manufacturer"
        foreach ($ManufacturerId in $Id) {
            $CurrentManufacturer = Get-NBDDCIM Manufacturer -Id $ManufacturerId -ErrorAction Stop

            if ($Force -or $PSCmdlet.ShouldProcess("$($CurrentManufacturer.Name)", "Delete manufacturer")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $CurrentManufacturer.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
