<#
.SYNOPSIS
    Updates an existing IPAM FHRPGroup in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM FHRPGroup in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMFHRPGroup

    Returns all IPAM FHRPGroup objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMFHRPGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [ValidateSet('vrrp2','vrrp3','carp','clusterxl','hsrp','glbp','other')][string]$Protocol,
        [uint16]$Group_Id,
        [string]$Name,
        [string]$Auth_Type,
        [string]$Auth_Key,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating IPAM FHRP Group"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-groups',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update FHRP group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
