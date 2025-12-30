<#
.SYNOPSIS
    Updates an existing CIMRackType in Netbox D module.

.DESCRIPTION
    Updates an existing CIMRackType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMRackType

    Returns all CIMRackType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMRackType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Manufacturer,
        [string]$Model,
        [string]$Slug,
        [string]$Form_Factor,
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
        Write-Verbose "Updating D CI MR ac kT yp e"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-types',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
