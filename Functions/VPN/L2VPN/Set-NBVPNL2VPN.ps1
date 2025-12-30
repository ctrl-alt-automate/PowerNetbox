<#
.SYNOPSIS
    Updates an existing VPN L2VPN in Netbox VPN module.

.DESCRIPTION
    Updates an existing VPN L2VPN in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVVPN L2VPN

    Returns all VPN L2VPN objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,[string]$Slug,[uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,
        [string]$Description,[string]$Comments,[uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Updating V PN L2V PN"
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
