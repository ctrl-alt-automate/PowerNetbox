<#
.SYNOPSIS
    Updates an existing tag in Netbox.

.DESCRIPTION
    Updates an existing tag in Netbox Extras module.

.PARAMETER Id
    The ID of the tag to update.

.PARAMETER Name
    Name of the tag.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description of the tag.

.PARAMETER Object_Types
    Object types this tag can be applied to.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBTag -Id 1 -Color "ff0000"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBTag {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [string[]]$Object_Types,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'tags', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Tag')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
