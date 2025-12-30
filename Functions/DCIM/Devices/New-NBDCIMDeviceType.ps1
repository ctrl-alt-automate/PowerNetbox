<#
.SYNOPSIS
    Creates a new CIMDeviceType in Netbox D module.

.DESCRIPTION
    Creates a new CIMDeviceType in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMDeviceType

    Returns all CIMDeviceType objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMDeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Manufacturer,
        [Parameter(Mandatory = $true)][string]$Model,
        [string]$Slug,
        [string]$Part_Number,
        [uint16]$U_Height,
        [bool]$Is_Full_Depth,
        [string]$Subdevice_Role,
        [string]$Airflow,
        [uint16]$Weight,
        [string]$Weight_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating D CI MD ev ic eT yp e"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Model, 'Create device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
