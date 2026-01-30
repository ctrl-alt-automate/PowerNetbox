<#
.SYNOPSIS
    Updates an existing PAMAggregate in Netbox I module.

.DESCRIPTION
    Updates an existing PAMAggregate in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMAggregate

    Returns all PAMAggregate objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBIPAMAggregate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Prefix,
        [uint64]$RIR,
        [uint64]$Tenant,
        [datetime]$Date_Added,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating IPAM Aggregate"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update aggregate')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
