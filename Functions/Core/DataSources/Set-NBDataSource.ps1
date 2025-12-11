<#
.SYNOPSIS
    Updates an existing data source in Netbox.

.DESCRIPTION
    Updates an existing data source in Netbox Core module.

.PARAMETER Id
    The ID of the data source to update.

.PARAMETER Name
    Name of the data source.

.PARAMETER Type
    Type of data source (local, git, amazon-s3).

.PARAMETER Source_Url
    Source URL for remote data sources.

.PARAMETER Description
    Description of the data source.

.PARAMETER Enabled
    Whether the data source is enabled.

.PARAMETER Ignore_Rules
    Patterns to ignore (one per line).

.PARAMETER Parameters
    Additional parameters (hashtable).

.PARAMETER Comments
    Comments.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBDataSource -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDataSource {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [ValidateSet('local', 'git', 'amazon-s3')]
        [string]$Type,

        [string]$Source_Url,

        [string]$Description,

        [bool]$Enabled,

        [string]$Ignore_Rules,

        [hashtable]$Parameters,

        [string]$Comments,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('core', 'data-sources', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Data Source')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
