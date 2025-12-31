<#
.SYNOPSIS
    Removes a bookmark from Netbox.

.DESCRIPTION
    Deletes a bookmark from Netbox by ID.

.PARAMETER Id
    The ID of the bookmark to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBBookmark -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBBookmark {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Bookmark"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Bookmark')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
