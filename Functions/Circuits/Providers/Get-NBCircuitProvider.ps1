<#
.SYNOPSIS
    Retrieves Providers objects from Netbox Circuits module.

.DESCRIPTION
    Retrieves Providers objects from Netbox Circuits module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBCircuitProvider

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBCircuitProvider {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ById',
                   Mandatory = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query',
                   Mandatory = $false)]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$ASN,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Account,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($i in $ID) {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'providers', $i))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName "Id"

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('circuits', 'providers'))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

            $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $URI -Raw:$Raw
        }
    }
}