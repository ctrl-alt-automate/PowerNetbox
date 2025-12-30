function Remove-NBDDCIM Region {
<#
    .SYNOPSIS
        Remove a region from Netbox

    .DESCRIPTION
        Deletes a region object from Netbox.

    .PARAMETER Id
        The ID of the region to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NBDDCIM Region -Id 1

        Deletes region with ID 1

    .EXAMPLE
        Get-NBDDCIM Region -Name "Old Region" | Remove-NBDDCIM Region

        Deletes regions matching the name "Old Region"
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
        Write-Verbose "Removing DCIM Region"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete region')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
