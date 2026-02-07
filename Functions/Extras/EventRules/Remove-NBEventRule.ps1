<#
.SYNOPSIS
    Removes an event rule from Netbox.

.DESCRIPTION
    Deletes an event rule from Netbox by ID.

.PARAMETER Id
    The ID of the event rule to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBEventRule -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBEventRule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Event Rule"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'event-rules', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Event Rule')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
