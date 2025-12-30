<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMDeviceRole

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDeviceRole {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ById', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Color,

        [bool]$VM_Role,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving D CI MD ev ic eR ol e"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($DRId in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-roles', $DRId))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-roles'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

            $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
        }
    }
    }
}
