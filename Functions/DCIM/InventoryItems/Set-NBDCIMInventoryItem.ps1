<#
.SYNOPSIS
    Updates an existing CIMInventoryItem in Netbox D module.

.DESCRIPTION
    Updates an existing CIMInventoryItem in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMInventoryItem

    Returns all CIMInventoryItem objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMInventoryItem {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [uint64]$Parent,
        [string]$Label,
        [uint64]$Role,
        [uint64]$Manufacturer,
        [string]$Part_Id,
        [string]$Serial,
        [string]$Asset_Tag,
        [bool]$Discovered,
        [string]$Description,
        [uint64]$Component_Type,
        [uint64]$Component_Id,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-items',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update inventory item')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
