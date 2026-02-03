<#
.SYNOPSIS
    Retrieves VLANTranslation Rule objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves VLANTranslation Rule objects from Netbox IPAM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBIPAMVLANTranslationRule

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMVLANTranslationRule {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,


        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Policy_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Local_Vid,
        [Parameter(ParameterSetName = 'Query')][uint64]$Remote_Vid,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,
        [switch]$Raw
    )
    process {
        Write-Verbose "Retrieving IPAM VLAN Translation Rule"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-rules',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-rules'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
            }
        }
    }
}
