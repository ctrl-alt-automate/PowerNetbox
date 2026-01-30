<#
.SYNOPSIS
    Creates a new CIMPowerOutletTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMPowerOutletTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMPowerOutletTemplate

    Returns all CIMPowerOutletTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMPowerOutletTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [uint64]$Power_Port,
        [string]$Feed_Leg,
        [string]$Description,
        [string]$Color,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Power Outlet Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlet-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power outlet template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
