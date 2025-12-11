<#
.SYNOPSIS
    Removes a contact assignment from Netbox.

.DESCRIPTION
    Removes a contact assignment from the Netbox tenancy module.
    Contact assignments link contacts to objects (sites, devices, circuits, etc.).
    Supports pipeline input from Get-NBContactAssignment.

.PARAMETER Id
    The database ID(s) of the contact assignment(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBContactAssignment -Id 1

    Removes contact assignment ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBContactAssignment -Id 1, 2, 3 -Force

    Removes multiple contact assignments without confirmation.

.EXAMPLE
    Get-NBContactAssignment -Contact_Id 5 | Remove-NBContactAssignment

    Removes all assignments for a specific contact via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/contactassignment/
#>
function Remove-NBContactAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        foreach ($AssignmentId in $Id) {
            $CurrentAssignment = Get-NBContactAssignment -Id $AssignmentId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments', $CurrentAssignment.Id))

            $URI = BuildNewURI -Segments $Segments

            # Build descriptive target for confirmation
            $Target = "Assignment ID $($CurrentAssignment.Id)"
            if ($CurrentAssignment.Contact -and $CurrentAssignment.Object) {
                $Target = "Contact '$($CurrentAssignment.Contact.Name)' -> '$($CurrentAssignment.Object.Name)'"
            }

            if ($Force -or $PSCmdlet.ShouldProcess($Target, 'Delete contact assignment')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
