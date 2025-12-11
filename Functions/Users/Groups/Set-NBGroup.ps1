<#
.SYNOPSIS
    Updates an existing group in Netbox.

.DESCRIPTION
    Updates an existing group in Netbox Users module.

.PARAMETER Id
    The ID of the group to update.

.PARAMETER Name
    Name of the group.

.PARAMETER Permissions
    Array of permission IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBGroup -Id 1 -Name "Updated Group Name"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64[]]$Permissions,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'groups', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Group')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
