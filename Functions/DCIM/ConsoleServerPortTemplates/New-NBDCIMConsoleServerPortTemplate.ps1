<#
.SYNOPSIS
    Creates a new CIMConsoleServerPortTemplate in Netbox D module.

.DESCRIPTION
    Creates a new CIMConsoleServerPortTemplate in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMConsoleServerPortTemplate

    Returns all CIMConsoleServerPortTemplate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMConsoleServerPortTemplate {
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
        Write-Verbose "Creating DCIM Console Server Port Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-server-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create console server port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
