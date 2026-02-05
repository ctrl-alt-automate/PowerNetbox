<#
.SYNOPSIS
    Creates a new Wireless Link in Netbox Wireless module.

.DESCRIPTION
    Creates a new Wireless Link in Netbox Wireless module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBWirelessLink

    Creates a new Wireless Link object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][uint64]$Interface_A,[Parameter(Mandatory = $true)][uint64]$Interface_B,
        [string]$SSID,[string]$Status,[uint64]$Tenant,[string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,
        [string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Creating Wireless Link"
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-links')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Interface_A to $Interface_B", 'Create wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
