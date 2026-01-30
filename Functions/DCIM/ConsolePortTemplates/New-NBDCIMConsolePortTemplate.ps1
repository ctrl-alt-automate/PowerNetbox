<#
.SYNOPSIS
    Creates a new CIMConsolePortTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMConsolePortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMConsolePortTemplate

    Returns all CIMConsolePortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMConsolePortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [string]$Description,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Console Port Te mp la te"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create console port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
