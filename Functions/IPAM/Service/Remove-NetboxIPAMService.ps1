function Remove-NetboxIPAMService {
<#
    .SYNOPSIS
        Remove a service from Netbox

    .DESCRIPTION
        Deletes a service object from Netbox.

    .PARAMETER Id
        The ID of the service to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMService -Id 1

        Deletes service with ID 1
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
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete service')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
