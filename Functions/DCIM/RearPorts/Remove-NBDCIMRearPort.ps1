<#
.SYNOPSIS
    Removes a DCIM RearPort from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM RearPort from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRearPort

    Returns all DCIM RearPort objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDCIMRearPort {

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

    begin {

    }

    process {
        Write-Verbose "Removing DCIM Rear Port"
        foreach ($RearPortID in $Id) {
            $CurrentPort = Get-NBDCIMRearPort -Id $RearPortID -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("Name: $($CurrentPort.Name) | ID: $($CurrentPort.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports', $CurrentPort.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }

    end {

    }
}
