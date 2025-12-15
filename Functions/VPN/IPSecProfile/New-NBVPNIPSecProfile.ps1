<#
.SYNOPSIS
    Creates a new IPSec Profile in Netbox VPN module.

.DESCRIPTION
    Creates a new IPSec Profile that combines IKE and IPSec policies for VPN configuration.

.PARAMETER Name
    The name of the IPSec profile (required)

.PARAMETER Mode
    IPSec mode: 'esp' (Encapsulating Security Payload) or 'ah' (Authentication Header) (required)

.PARAMETER IKE_Policy
    The IKE policy ID to associate with this profile (required)

.PARAMETER IPSec_Policy
    The IPSec policy ID to associate with this profile (required)

.PARAMETER Description
    Description of the profile

.PARAMETER Comments
    Additional comments

.PARAMETER Custom_Fields
    Hashtable of custom field values

.PARAMETER Raw
    Return the raw API response

.EXAMPLE
    New-NBVPNIPSecProfile -Name "IPSec-Profile-1" -Mode "esp" -IKE_Policy 1 -IPSec_Policy 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('esp', 'ah')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [uint64]$IKE_Policy,

        [Parameter(Mandatory = $true)]
        [uint64]$IPSec_Policy,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'ipsec-profiles'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec profile')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
