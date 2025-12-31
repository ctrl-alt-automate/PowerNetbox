<#
.SYNOPSIS
    Creates a new CIMVirtualDeviceContext in Netbox D module.

.DESCRIPTION
    Creates a new CIMVirtualDeviceContext in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMVirtualDeviceContext

    Returns all CIMVirtualDeviceContext objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMVirtualDeviceContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][uint64]$Device,
        [ValidateSet('active','planned','offline')][string]$Status = 'active',
        [string]$Identifier,
        [uint64]$Tenant,
        [uint64]$Primary_Ip4,
        [uint64]$Primary_Ip6,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating D CI MV ir tu al De vi ce Co nt ex t"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-device-contexts'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create virtual device context')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
