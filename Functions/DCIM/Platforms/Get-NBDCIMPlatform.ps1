<#
.SYNOPSIS
    Retrieves Platforms objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Platforms objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMPlatform

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMPlatform {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Manufacturer_Id,

        [string]$Manufacturer,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving DCIM Platform"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($PlatformID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'platforms', $PlatformID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'platforms'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

            $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
        }
    }
    }
}
