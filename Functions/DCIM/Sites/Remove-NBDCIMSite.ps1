<#
.SYNOPSIS
    Removes a DCIM Site from Netbox.

.DESCRIPTION
    Removes a DCIM Site from Netbox.
    Supports pipeline input for Id parameter.

.EXAMPLE
    Remove-NBDCIMSite -Id 1

.EXAMPLE
    Get-NBDCIMSite -Name 'My Site' | Remove-NBDCIMSite -Confirm:$false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMSite {

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing DCIM Site"

        if ($pscmdlet.ShouldProcess("ID $Id", "Remove Site")) {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites', $Id))

            $URI = BuildNewURI -Segments $Segments

            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
