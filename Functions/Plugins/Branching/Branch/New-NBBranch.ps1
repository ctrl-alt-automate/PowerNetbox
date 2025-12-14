<#
.SYNOPSIS
    Creates a new branch in Netbox.

.DESCRIPTION
    Creates a new branch using the Netbox Branching plugin.
    A branch allows you to make changes in isolation before merging to main.

.PARAMETER Name
    The name of the branch. This is required.

.PARAMETER Description
    An optional description of the branch.

.PARAMETER Tags
    Array of tag IDs to assign to the branch.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response.

.OUTPUTS
    [PSCustomObject] The created branch object.

.EXAMPLE
    New-NBBranch -Name "feature/new-datacenter"
    Create a new branch.

.EXAMPLE
    New-NBBranch -Name "hotfix/urgent" -Description "Emergency fix for production"
    Create a branch with description.

.LINK
    Get-NBBranch
    Set-NBBranch
    Remove-NBBranch
#>
function New-NBBranch {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Description,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        CheckNetboxIsConnected

        $Segments = [System.Collections.ArrayList]::new(@('plugins', 'netbox-branching', 'branches'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Branch')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
