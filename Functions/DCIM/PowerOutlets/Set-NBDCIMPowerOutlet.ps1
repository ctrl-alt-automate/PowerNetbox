<#
.SYNOPSIS
    Updates an existing DCIM PowerOutlet in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM PowerOutlet in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerOutlet

    Returns all DCIM PowerOutlet objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerOutlet {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint64]$Power_Port,
        [string]$Feed_Leg,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Power Outlet"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlets',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power outlet')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
