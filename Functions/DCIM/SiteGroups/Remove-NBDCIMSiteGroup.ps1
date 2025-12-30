function Remove-NBDCIMSiteGroup {
<#
    .SYNOPSIS
        Remove a site group from Netbox

    .DESCRIPTION
        Deletes a site group object from Netbox.

    .PARAMETER Id
        The ID of the site group to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NBDDCIM SiteGroup -Id 1

        Deletes site group with ID 1

    .EXAMPLE
        Get-NBDDCIM SiteGroup -Name "Old Group" | Remove-NBDDCIM SiteGroup

        Deletes site groups matching the name "Old Group"
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
        Write-Verbose "Removing DCIM SiteG ro up"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'site-groups', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete site group')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
