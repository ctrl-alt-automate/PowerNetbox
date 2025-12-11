function Remove-NBIPAMASNRange {
<#
    .SYNOPSIS
        Remove an ASN range from Netbox

    .DESCRIPTION
        Deletes an ASN range object from Netbox.

    .PARAMETER Id
        The ID of the ASN range to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NBIPAMASNRange -Id 1

        Deletes ASN range with ID 1
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
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete ASN range')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
