<#
.SYNOPSIS
    Creates a new CIMFrontPortTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMFrontPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMFrontPortTemplate

    Returns all CIMFrontPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMFrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [Parameter(Mandatory = $true)][string]$Type,
        [string]$Color,
        [Parameter(Mandatory = $true)][uint64]$Rear_Port,
        [uint16]$Rear_Port_Position,
        [string]$Description,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Front Port Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','front-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
