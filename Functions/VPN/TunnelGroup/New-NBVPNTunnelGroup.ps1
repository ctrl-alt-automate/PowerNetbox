<#
.SYNOPSIS
    Creates a new VPN Tunnel Group in Netbox.

.DESCRIPTION
    Creates a new VPN Tunnel Group in Netbox VPN module.

.PARAMETER Name
    The tunnel group name.

.PARAMETER Slug
    The unique slug for the tunnel group.

.PARAMETER Description
    Description of the tunnel group.

.PARAMETER CustomFields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVPNTunnelGroup -Name "Corporate VPN" -Slug "corporate-vpn"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNTunnelGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [string]$Description,

        [hashtable]$CustomFields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating VPN Tunnel Group"
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnel-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create tunnel group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
