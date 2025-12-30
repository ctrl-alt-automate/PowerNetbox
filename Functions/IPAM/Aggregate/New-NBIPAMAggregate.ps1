<#
.SYNOPSIS
    Creates a new PAMAggregate in Netbox I module.

.DESCRIPTION
    Creates a new PAMAggregate in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBIPAMAggregate

    Returns all PAMAggregate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBIPAMAggregate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Prefix,
        [Parameter(Mandatory = $true)][uint64]$RIR,
        [uint64]$Tenant,
        [datetime]$Date_Added,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating I PA MA gg re ga te"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Prefix, 'Create aggregate')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
