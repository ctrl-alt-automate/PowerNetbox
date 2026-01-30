<#
.SYNOPSIS
    Creates a new PAMVLANTranslationRule in Netbox I module.

.DESCRIPTION
    Creates a new PAMVLANTranslationRule in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMVLANTranslationRule

    Returns all PAMVLANTranslationRule objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Policy,
        [Parameter(Mandatory = $true)][ValidateRange(1, 4094)][uint16]$Local_Vid,
        [Parameter(Mandatory = $true)][ValidateRange(1, 4094)][uint16]$Remote_Vid,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating IPAM VLANT ra ns la ti on Ru le"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-rules'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Local_Vid -> $Remote_Vid", 'Create VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
