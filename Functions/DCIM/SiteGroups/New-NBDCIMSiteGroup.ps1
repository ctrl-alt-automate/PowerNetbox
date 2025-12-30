function New-NBDCIMSiteGroup {
<#
    .SYNOPSIS
        Create a new site group in Netbox

    .DESCRIPTION
        Creates a new site group object in Netbox.
        Site groups are used to organize sites by functional role (e.g., production, staging, DR).

    .PARAMETER Name
        The name of the site group (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER Parent
        The parent site group ID for nested groups

    .PARAMETER Description
        A description of the site group

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .EXAMPLE
        New-NBDCIMSiteGroup -Name "Production" -Slug "production"

        Creates a new site group named "Production"

    .EXAMPLE
        New-NBDCIMSiteGroup -Name "DR Sites" -Slug "dr-sites" -Parent 1

        Creates a new site group as a child of site group 1
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating D CI MS it eG ro up"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'site-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new site group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
