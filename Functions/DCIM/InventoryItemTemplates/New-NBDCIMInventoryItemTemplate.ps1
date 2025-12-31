<#
.SYNOPSIS
    Creates a new CIMInventoryItemTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMInventoryItemTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMInventoryItemTemplate

    Returns all CIMInventoryItemTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMInventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Parent,
        [string]$Label,
        [uint64]$Role,
        [uint64]$Manufacturer,
        [string]$Part_Id,
        [string]$Description,
        [uint64]$Component_Type,
        [string]$Component_Name,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating D CI MI nv en to ry It em Te mp la te"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-item-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
