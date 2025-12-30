<#
.SYNOPSIS
    Creates a new provider network in Netbox.

.DESCRIPTION
    Creates a new provider network in Netbox.

.PARAMETER Provider
    Provider ID.

.PARAMETER Name
    Name of the network.

.PARAMETER Service_Id
    Service identifier.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitProviderNetwork -Provider 1 -Name "MPLS Network"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitProviderNetwork {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Provider,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Service_Id,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Circuit Provider Network"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-networks'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Provider Network')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
