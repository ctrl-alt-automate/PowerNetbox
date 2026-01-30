<#
.SYNOPSIS
    Creates a new CIMPowerFeed in Netbox D module.

.DESCRIPTION
    Creates a new CIMPowerFeed in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPowerFeed

    Returns all CIMPowerFeed objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Power_Panel,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Rack,
        [string]$Status,
        [string]$Type,
        [string]$Supply,
        [string]$Phase,
        [uint16]$Voltage,
        [uint16]$Amperage,
        [uint16]$Max_Utilization,
        [bool]$Mark_Connected,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Power Feed"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-feeds'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
