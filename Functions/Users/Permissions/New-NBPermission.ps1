<#
.SYNOPSIS
    Creates a new permission in Netbox.

.DESCRIPTION
    Creates a new permission in Netbox Users module.

.PARAMETER Name
    Name of the permission.

.PARAMETER Description
    Description of the permission.

.PARAMETER Enabled
    Whether the permission is enabled.

.PARAMETER Object_Types
    Object types this permission applies to.

.PARAMETER Actions
    Allowed actions (view, add, change, delete).

.PARAMETER Constraints
    JSON constraints for filtering objects.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Users
    Array of user IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBPermission -Name "View Devices" -Object_Types @("dcim.device") -Actions @("view")

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBPermission {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Description,

        [bool]$Enabled,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [Parameter(Mandatory = $true)]
        [ValidateSet('view', 'add', 'change', 'delete')]
        [string[]]$Actions,

        $Constraints,

        [uint64[]]$Groups,

        [uint64[]]$Users,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'permissions'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Permission')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
