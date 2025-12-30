function Remove-NBIPAMASN {
<#
    .SYNOPSIS
        Remove an ASN from Netbox

    .DESCRIPTION
        Deletes an ASN (Autonomous System Number) object from Netbox.

    .PARAMETER Id
        The ID of the ASN to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NBIPAMASN -Id 1

        Deletes ASN with ID 1
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
        Write-Verbose "Removing I PA MA SN"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete ASN')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
