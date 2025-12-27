<#
.SYNOPSIS
    Creates a new API token in Netbox.

.DESCRIPTION
    Creates a new API token in Netbox Users module.

.PARAMETER User
    User ID for the token.

.PARAMETER Description
    Description of the token.

.PARAMETER Expires
    Expiration date (datetime).

.PARAMETER Key
    Custom token key (auto-generated if not provided).

.PARAMETER Write_Enabled
    Whether write operations are enabled.

.PARAMETER Allowed_Ips
    Array of allowed IP addresses/networks.

.PARAMETER Enabled
    Whether the token is enabled (Netbox 4.5+ only). Defaults to true.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBToken -User 1 -Description "API automation"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBToken {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$User,

        [string]$Description,

        [datetime]$Expires,

        [string]$Key,

        [bool]$Write_Enabled,

        [string[]]$Allowed_Ips,

        [bool]$Enabled,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'tokens'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("User $User", 'Create Token')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
