function Remove-NBIPAMRouteTarget {
<#
    .SYNOPSIS
        Remove a route target from Netbox

    .DESCRIPTION
        Deletes a route target object from Netbox.

    .PARAMETER Id
        The ID of the route target to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NBIPAMRouteTarget -Id 1

        Deletes route target with ID 1

    .EXAMPLE
        Get-NBIPAMRouteTarget -Name "65001:999" | Remove-NBIPAMRouteTarget

        Deletes route targets matching the specified value
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing IPAM Route Target"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete route target')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
