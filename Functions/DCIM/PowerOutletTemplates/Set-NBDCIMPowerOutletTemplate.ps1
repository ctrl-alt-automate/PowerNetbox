<#
.SYNOPSIS
    Updates an existing DCIM Power OutletTemplate in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM Power OutletTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDDCIM Power OutletTemplate

    Returns all DCIM Power OutletTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerOutletTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [uint64]$Power_Port,
        [string]$Feed_Leg,
        [string]$Description,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Power Outlet Te mp la te"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlet-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power outlet template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
