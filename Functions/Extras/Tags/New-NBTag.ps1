<#
.SYNOPSIS
    Creates a new tag in Netbox.

.DESCRIPTION
    Creates a new tag in Netbox Extras module.

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
    New-NBTag -Name "Production" -Slug "production" -Color "00ff00"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBTag {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [string[]]$Object_Types,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'tags'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Tag')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
