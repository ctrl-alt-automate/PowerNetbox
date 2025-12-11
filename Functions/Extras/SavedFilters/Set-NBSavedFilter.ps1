<#
.SYNOPSIS
    Updates an existing saved filter in Netbox.

.DESCRIPTION
    Updates an existing saved filter in Netbox Extras module.

.PARAMETER Id
    The ID of the saved filter to update.

.PARAMETER Name
    Name of the saved filter.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Object_Types
    Object types this filter applies to.

.PARAMETER Description
    Description of the filter.

.PARAMETER Weight
    Display weight.

.PARAMETER Enabled
    Whether the filter is enabled.

.PARAMETER Shared
    Whether the filter is shared.

.PARAMETER Parameters
    Filter parameters (hashtable).

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBSavedFilter -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBSavedFilter {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [string[]]$Object_Types,

        [string]$Description,

        [uint16]$Weight,

        [bool]$Enabled,

        [bool]$Shared,

        [hashtable]$Parameters,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'saved-filters', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Saved Filter')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
