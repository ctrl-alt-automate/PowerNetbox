<#
.SYNOPSIS
    Creates a new bookmark in Netbox.

.DESCRIPTION
    Creates a new bookmark in Netbox Extras module.

.PARAMETER Object_Type
    Object type (e.g., "dcim.device").

.PARAMETER Object_Id
    Object ID.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBBookmark -Object_Type "dcim.device" -Object_Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBBookmark {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Object_Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Object_Id,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("$Object_Type $Object_Id", 'Create Bookmark')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
