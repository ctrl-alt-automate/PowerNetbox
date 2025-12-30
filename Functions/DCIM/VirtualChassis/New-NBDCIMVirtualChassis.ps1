<#
.SYNOPSIS
    Creates a new CIMVirtualChassis in Netbox D module.

.DESCRIPTION
    Creates a new CIMVirtualChassis in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMVirtualChassis

    Returns all CIMVirtualChassis objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMVirtualChassis {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Domain,
        [uint64]$Master,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating D CI MV ir tu al Ch as si s"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-chassis'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create virtual chassis')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
