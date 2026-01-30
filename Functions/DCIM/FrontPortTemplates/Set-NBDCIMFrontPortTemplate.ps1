<#
.SYNOPSIS
    Updates an existing CIMFrontPortTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMFrontPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMFrontPortTemplate

    Returns all CIMFrontPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMFrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [string]$Color,
        [uint64]$Rear_Port,
        [uint16]$Rear_Port_Position,
        [string]$Description,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Front Port Te mp la te"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','front-port-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
