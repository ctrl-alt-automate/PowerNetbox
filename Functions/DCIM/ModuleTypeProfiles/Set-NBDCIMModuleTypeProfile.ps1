<#
.SYNOPSIS
    Updates an existing CIMModuleTypeProfile in Netbox D module.

.DESCRIPTION
    Updates an existing CIMModuleTypeProfile in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMModuleTypeProfile

    Returns all CIMModuleTypeProfile objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBDCIMModuleTypeProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Module TypeP ro fi le"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-type-profiles',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module type profile')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
