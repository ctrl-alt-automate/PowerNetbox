<#
.SYNOPSIS
    Updates an existing PNL2VPNTermination in Netbox V module.

.DESCRIPTION
    Updates an existing PNL2VPNTermination in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNL2VPNTermination

    Returns all PNL2VPNTermination objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$L2VPN,[string]$Assigned_Object_Type,[uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Updating V PN L2V PN Te rm in at io n"
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
