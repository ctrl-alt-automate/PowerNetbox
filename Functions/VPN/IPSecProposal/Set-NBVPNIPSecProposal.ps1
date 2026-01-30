<#
.SYNOPSIS
    Updates an existing PNIPSecProposal in Netbox V module.

.DESCRIPTION
    Updates an existing PNIPSecProposal in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVPNIPSecProposal

    Returns all PNIPSecProposal objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint32]$SA_Lifetime_Seconds,[uint32]$SA_Lifetime_Data,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[switch]$Raw)
    process {
        Write-Verbose "Updating VPN IPSec Proposal"
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-proposals',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
