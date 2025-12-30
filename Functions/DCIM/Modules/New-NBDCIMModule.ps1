<#
.SYNOPSIS
    Creates a new CIMModule in Netbox D module.

.DESCRIPTION
    Creates a new CIMModule in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMModule

    Returns all CIMModule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][uint64]$Module_Bay,
        [Parameter(Mandatory = $true)][uint64]$Module_Type,
        [string]$Status,
        [string]$Serial,
        [string]$Asset_Tag,
        [string]$Description,
        [string]$Comments,
        [bool]$Replicate_Components,
        [bool]$Adopt_Components,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating D CI MM od ul e"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','modules'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Device $Device", 'Create module')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
