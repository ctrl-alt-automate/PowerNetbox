<#
.SYNOPSIS
    Updates an existing WirelessLAN in Netbox W module.

.DESCRIPTION
    Updates an existing WirelessLAN in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBWirelessLAN

    Returns all WirelessLAN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$SSID,[uint64]$Group,[string]$Status,[uint64]$VLAN,[uint64]$Tenant,
        [string]$Auth_Type,[string]$Auth_Cipher,[string]$Auth_PSK,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Updating Wireless LAN"
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
