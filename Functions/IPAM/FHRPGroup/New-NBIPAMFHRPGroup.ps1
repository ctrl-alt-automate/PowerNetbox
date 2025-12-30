<#
.SYNOPSIS
    Creates a new IPAM FHRP Group in Netbox IPAM module.

.DESCRIPTION
    Creates a new IPAM FHRP Group in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIIPAM FHRP Group

    Returns all IPAM FHRP Group objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMFHRPGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][ValidateSet('vrrp2','vrrp3','carp','clusterxl','hsrp','glbp','other')][string]$Protocol,
        [Parameter(Mandatory = $true)][uint16]$Group_Id,
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
        Write-Verbose "Creating IPAM FHRP Group"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Protocol Group $Group_Id", 'Create FHRP group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
