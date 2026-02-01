<#
.SYNOPSIS
    Updates an existing DCIM VirtualDeviceContext in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM VirtualDeviceContext in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMVirtualDeviceContext

    Returns all DCIM VirtualDeviceContext objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMVirtualDeviceContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [uint64]$Device,
        [ValidateSet('active','planned','offline')][string]$Status,
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
        Write-Verbose "Updating DCIM Virtual Device Context"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-device-contexts',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update virtual device context')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
