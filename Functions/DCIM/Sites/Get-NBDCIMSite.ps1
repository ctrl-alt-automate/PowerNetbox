<#
.SYNOPSIS
    Retrieves Sites objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Sites objects from Netbox DCIM module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMSite

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMSite {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Facility,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$ASN,

        [Parameter(ParameterSetName = 'Query')]
        [decimal]$Latitude,

        [Parameter(ParameterSetName = 'Query')]
        [decimal]$Longitude,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contact_Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contact_Phone,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contact_Email,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Group_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant_Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Region_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Region,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($Site_ID in $ID) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites', $Site_Id))

                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName "Id"

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw
            }
        }
    }
}
