<#
.SYNOPSIS
    Updates an existing CIMPowerPortTemplate in Netbox D module.

.DESCRIPTION
    Updates an existing CIMPowerPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMPowerPortTemplate

    Returns all CIMPowerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMPowerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [uint16]$Maximum_Draw,
        [uint16]$Allocated_Draw,
        [string]$Description,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Power Port Te mp la te"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-port-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
