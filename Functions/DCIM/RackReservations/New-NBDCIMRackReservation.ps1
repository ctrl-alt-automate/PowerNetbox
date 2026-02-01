<#
.SYNOPSIS
    Creates a new DCIM RackReservation in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM RackReservation in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMRackReservation

    Returns all DCIM RackReservation objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMRackReservation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Rack,
        [Parameter(Mandatory = $true)][uint16[]]$Units,
        [Parameter(Mandatory = $true)][uint64]$User,
        [uint64]$Tenant,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM RackR es er va ti on"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-reservations'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Rack $Rack", 'Create rack reservation')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
