<#
.SYNOPSIS
    Creates a new IPAM VLANTranslationPolicy in Netbox IPAM module.

.DESCRIPTION
    Creates a new IPAM VLANTranslationPolicy in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMVLANTranslationPolicy

    Creates a new IPAM VLAN Translation Policy object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMVLANTranslationPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating IPAM VLAN Translation Policy"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-policies'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create VLAN translation policy')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
