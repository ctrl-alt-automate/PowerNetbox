<#
.SYNOPSIS
    Updates an existing IPAM VLANTranslationRule in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM VLANTranslationRule in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMVLANTranslationRule

    Updates an existing IPAM VLAN Translation Rule object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Policy,
        [ValidateRange(1, 4094)][uint16]$Local_Vid,
        [ValidateRange(1, 4094)][uint16]$Remote_Vid,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating IPAM VLAN Translation Rule"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-rules',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
