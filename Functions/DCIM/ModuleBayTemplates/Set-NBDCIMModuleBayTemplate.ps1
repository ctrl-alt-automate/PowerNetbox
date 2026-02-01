<#
.SYNOPSIS
    Updates an existing DCIM ModuleBayTemplate in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM ModuleBayTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMModuleBayTemplate

    Returns all DCIM ModuleBayTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMModuleBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [string]$Name,
        [string]$Label,
        [string]$Position,
        [string]$Description,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Module Bay Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bay-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
