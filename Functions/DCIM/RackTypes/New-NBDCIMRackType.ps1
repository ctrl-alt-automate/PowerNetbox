<#
.SYNOPSIS
    Creates a new CIMRackType in Netbox D module.

.DESCRIPTION
    Creates a new CIMRackType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMRackType

    Returns all CIMRackType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMRackType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Manufacturer,
        [Parameter(Mandatory = $true)][string]$Model,
        [string]$Slug,
        [Parameter(Mandatory = $true)][string]$Form_Factor,
        [uint16]$Width,
        [uint16]$U_Height,
        [uint16]$Starting_Unit,
        [uint16]$Outer_Width,
        [uint16]$Outer_Depth,
        [string]$Outer_Unit,
        [uint16]$Weight,
        [uint16]$Max_Weight,
        [string]$Weight_Unit,
        [string]$Mounting_Depth,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Rack Type"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Model, 'Create rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
