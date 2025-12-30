<#
.SYNOPSIS
    Creates a new irelessLAN in Netbox W module.

.DESCRIPTION
    Creates a new irelessLAN in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBWirelessLAN

    Returns all irelessLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$SSID,[uint64]$Group,[string]$Status,[uint64]$VLAN,[uint64]$Tenant,
        [string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Creating Wireless LAN"
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($SSID, 'Create wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
