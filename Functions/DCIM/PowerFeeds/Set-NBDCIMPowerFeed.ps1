<#
.SYNOPSIS
    Updates an existing DCIM PowerFeed in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM PowerFeed in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerFeed

    Returns all DCIM PowerFeed objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Power_Panel,
        [string]$Name,
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
        Write-Verbose "Updating DCIM Power Feed"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-feeds',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
