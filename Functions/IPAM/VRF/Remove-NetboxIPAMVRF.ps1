function Remove-NetboxIPAMVRF {
<#
    .SYNOPSIS
        Remove a VRF from Netbox

    .DESCRIPTION
        Deletes a VRF (Virtual Routing and Forwarding) object from Netbox.

    .PARAMETER Id
        The ID of the VRF to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMVRF -Id 1

        Deletes VRF with ID 1

    .EXAMPLE
        Get-NetboxIPAMVRF -Name "Test-VRF" | Remove-NetboxIPAMVRF

        Deletes VRFs matching the name "Test-VRF"
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
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete VRF')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
