<#
.SYNOPSIS
    Updates an existing branch in Netbox.

.DESCRIPTION
    Updates properties of an existing branch using the Netbox Branching plugin.

.PARAMETER Id
    The ID of the branch to update.

.PARAMETER Name
    The new name for the branch.

.PARAMETER Description
    The new description for the branch.

.PARAMETER Tags
    Array of tag IDs to assign to the branch.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response.

.OUTPUTS
    [PSCustomObject] The updated branch object.

.EXAMPLE
    Set-NBBranch -Id 1 -Description "Updated description"
    Update a branch's description.

.EXAMPLE
    Get-NBBranch -Name "feature" | Set-NBBranch -Name "feature/renamed"
    Rename a branch using pipeline.

.LINK
    Get-NBBranch
    New-NBBranch
    Remove-NBBranch
#>
function Set-NBBranch {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        CheckNetboxIsConnected

        $Segments = [System.Collections.ArrayList]::new(@('plugins', 'netbox-branching', 'branches', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Branch ID $Id", 'Update Branch')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
