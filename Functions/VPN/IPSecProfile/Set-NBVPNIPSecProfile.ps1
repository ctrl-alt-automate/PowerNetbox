<#
.SYNOPSIS
    Updates an existing PNIPSecProfile in Netbox V module.

.DESCRIPTION
    Updates an existing PNIPSecProfile in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNIPSecProfile

    Returns all PNIPSecProfile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Mode,[uint64]$IKE_Policy,[uint64]$IPSec_Policy,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Updating V PN IP Se cP ro fi le"
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-profiles',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
