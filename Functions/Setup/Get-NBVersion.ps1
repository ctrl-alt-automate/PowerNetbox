<#
.SYNOPSIS
    Retrieves Get-NBVersion.ps1 objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Get-NBVersion.ps1 objects from Netbox Setup module.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBVersion

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVersion {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    $Segments = [System.Collections.ArrayList]::new(@('status'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary @{
        'format' = 'json'
    }

    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters -SkipConnectedCheck

    InvokeNetboxRequest -URI $URI
}
