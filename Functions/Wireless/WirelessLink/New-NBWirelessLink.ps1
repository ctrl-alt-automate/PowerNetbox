<#
.SYNOPSIS
    Creates a new Wireless Link in Netbox Wireless module.

.DESCRIPTION
    Creates a new Wireless Link in Netbox Wireless module.

.PARAMETER Interface_A
    The first interface ID for the wireless link (required).

.PARAMETER Interface_B
    The second interface ID for the wireless link (required).

.PARAMETER SSID
    The SSID for the wireless link.

.PARAMETER Status
    Wireless link status.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Auth_Type
    Authentication type.

.PARAMETER Auth_Cipher
    Authentication cipher.

.PARAMETER Auth_PSK
    Pre-shared key for authentication.

.PARAMETER Description
    Description of the wireless link.

.PARAMETER Comments
    Additional comments.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBWirelessLink -Interface_A 1 -Interface_B 2

    Creates a new Wireless Link between two interfaces.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Interface_A,

        [Parameter(Mandatory = $true)]
        [uint64]$Interface_B,

        [string]$SSID,

        [string]$Status,

        [uint64]$Tenant,

        [string]$Auth_Type,

        [string]$Auth_Cipher,

        [string]$Auth_PSK,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Wireless Link"
        $Segments = [System.Collections.ArrayList]::new(@('wireless', 'wireless-links'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("$Interface_A to $Interface_B", 'Create wireless link')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
