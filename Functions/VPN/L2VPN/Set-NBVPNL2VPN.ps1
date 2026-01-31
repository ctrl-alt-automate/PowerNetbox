<#
.SYNOPSIS
    Updates an existing PNL2VPN in Netbox V module.

.DESCRIPTION
    Updates an existing PNL2VPN in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNL2VPN

    Returns all PNL2VPN objects.

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
        Write-Verbose "Updating VPN L2VPN"
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
