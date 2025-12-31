<#
.SYNOPSIS
    Creates a new PAMRole in Netbox I module.

.DESCRIPTION
    Creates a new PAMRole in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMRole

    Returns all PAMRole objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [uint16]$Weight,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating IPA MR ol e"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'roles'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Name, 'Create IPAM role')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
