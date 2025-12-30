<#
.SYNOPSIS
    Removes a DCIM Front Port from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Front Port from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDDCIM Front Port

    Returns all DCIM Front Port objects.

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
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        Write-Verbose "Removing DCIM Front Port"
        foreach ($FrontPortID in $Id) {
            $CurrentPort = Get-NBDDCIM Front Port -Id $FrontPortID -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("Name: $($CurrentPort.Name) | ID: $($CurrentPort.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports', $CurrentPort.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}
