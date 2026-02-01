<#
.SYNOPSIS
    Creates a new DCIM InterfaceTemplate in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM InterfaceTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMInterfaceTemplate

    Returns all DCIM InterfaceTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMInterfaceTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [Parameter(Mandatory = $true)][string]$Type,
        [bool]$Enabled,
        [bool]$Mgmt_Only,
        [string]$Description,
        [string]$Poe_Mode,
        [string]$Poe_Type,
        [string]$Rf_Role,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Interface Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','interface-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create interface template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
