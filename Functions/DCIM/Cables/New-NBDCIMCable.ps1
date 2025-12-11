<#
.SYNOPSIS
    Creates a new CIMCable in Netbox D module.

.DESCRIPTION
    Creates a new CIMCable in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMCable

    Returns all CIMCable objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$A_Terminations_Type,
        [Parameter(Mandatory = $true)][uint64[]]$A_Terminations,
        [Parameter(Mandatory = $true)][string]$B_Terminations_Type,
        [Parameter(Mandatory = $true)][uint64[]]$B_Terminations,
        [string]$Type,
        [string]$Status,
        [uint64]$Tenant,
        [string]$Label,
        [string]$Color,
        [decimal]$Length,
        [string]$Length_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim','cables'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Label, 'Create cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
