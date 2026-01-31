
function Remove-NBIPAMAddressRange {
    <#
    .SYNOPSIS
        Remove an IP address range from Netbox

    .DESCRIPTION
        Removes/deletes an IP address range from Netbox by ID

    .PARAMETER Id
        Database ID of the IP address range object.

    .PARAMETER Force
        Do not confirm.

    .EXAMPLE
        PS C:\> Remove-NBIPAMAddressRange -Id 1234

#>

    [CmdletBinding(ConfirmImpact = 'High',
                   SupportsShouldProcess = $true)]
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
        Write-Verbose "Removing IPAM Address Range"
        foreach ($Range_Id in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges', $Range_Id))

            if ($Force -or $pscmdlet.ShouldProcess("IP Range ID $Range_Id", "Delete")) {
                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
