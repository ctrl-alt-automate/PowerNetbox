<#
.SYNOPSIS
    Creates a new DCIM PowerPortTemplate in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM PowerPortTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDDCIM PowerPortTemplate

    Returns all DCIM PowerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDDCIM PowerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [uint16]$Maximum_Draw,
        [uint16]$Allocated_Draw,
        [string]$Description,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Power Port Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
