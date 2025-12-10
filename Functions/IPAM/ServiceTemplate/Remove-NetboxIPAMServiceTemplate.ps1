function Remove-NetboxIPAMServiceTemplate {
<#
    .SYNOPSIS
        Remove a service template from Netbox

    .DESCRIPTION
        Deletes a service template object from Netbox.

    .PARAMETER Id
        The ID of the service template to delete (required)

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        Remove-NetboxIPAMServiceTemplate -Id 1

        Deletes service template with ID 1
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
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete service template')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
