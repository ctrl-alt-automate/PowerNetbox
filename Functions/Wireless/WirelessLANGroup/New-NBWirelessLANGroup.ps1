<#
.SYNOPSIS
    Creates a new irelessLANGroup in Netbox W module.

.DESCRIPTION
    Creates a new irelessLANGroup in Netbox W module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBWirelessLANGroup

    Creates a new Wireless LAN Group object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,[uint64]$Parent,[string]$Description,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Creating Wireless LAN Group"
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lan-groups')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
