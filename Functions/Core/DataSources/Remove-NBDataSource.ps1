<#
.SYNOPSIS
    Removes a data source from Netbox.

.DESCRIPTION
    Deletes a data source from Netbox by ID.

.PARAMETER Id
    The ID of the data source to delete.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBDataSource -Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Remove-NBDataSource {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Data Source"
        $Segments = [System.Collections.ArrayList]::new(@('core', 'data-sources', $Id))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete Data Source')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
