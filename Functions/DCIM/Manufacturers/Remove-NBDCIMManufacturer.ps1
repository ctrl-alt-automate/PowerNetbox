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
        Remove-NBDCIMManufacturer -Id 1

        Deletes manufacturer with ID 1 (with confirmation)

    .EXAMPLE
        Remove-NBDCIMManufacturer -Id 1 -Confirm:$false

        Deletes manufacturer with ID 1 without confirmation

    .EXAMPLE
        Get-NBDCIMManufacturer -Name "OldVendor" | Remove-NBDCIMManufacturer

        Deletes manufacturer named "OldVendor"
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing DCIM Manufacturer"
        foreach ($ManufacturerId in $Id) {
            if ($Force -or $PSCmdlet.ShouldProcess("Manufacturer ID $ManufacturerId", "Delete manufacturer")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $ManufacturerId))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
