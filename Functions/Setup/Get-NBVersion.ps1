<#
.SYNOPSIS
    Retrieves version and status information from the Netbox API.

.DESCRIPTION
    Calls the /api/status/ endpoint to retrieve the Netbox version and status information.

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

    $URI = BuildNewURI -Segments $Segments -SkipConnectedCheck

    InvokeNetboxRequest -URI $URI
}
