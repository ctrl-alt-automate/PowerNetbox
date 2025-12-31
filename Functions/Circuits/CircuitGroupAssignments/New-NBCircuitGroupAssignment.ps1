<#
.SYNOPSIS
    Creates a new circuit group assignment in Netbox.

.DESCRIPTION
    Creates a new circuit group assignment in Netbox.

.PARAMETER Group
    Circuit group ID.

.PARAMETER Circuit
    Circuit ID.

.PARAMETER Priority
    Priority (primary, secondary, tertiary, inactive).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBCircuitGroupAssignment -Group 1 -Circuit 1 -Priority "primary"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBCircuitGroupAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Group,

        [Parameter(Mandatory = $true)]
        [uint64]$Circuit,

        [ValidateSet('primary', 'secondary', 'tertiary', 'inactive')]
        [string]$Priority,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Circuit Group Assignment"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-group-assignments'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Group $Group Circuit $Circuit", 'Create Circuit Group Assignment')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
