<#
.SYNOPSIS
    Removes a DCIM FrontPort from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM FrontPort from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMFrontPort

    Deletes a DCIM FrontPort object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMFrontPort {

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing DCIM Front Port"
        foreach ($FrontPortID in $Id) {
            if ($Force -or $pscmdlet.ShouldProcess("Front Port ID $FrontPortID", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports', $FrontPortID))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
