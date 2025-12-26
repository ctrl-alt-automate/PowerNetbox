<#
.SYNOPSIS
    Creates a new owner in Netbox (Netbox 4.5+).

.DESCRIPTION
    Creates a new owner in Netbox Users module.
    Owners represent sets of users and/or groups for tracking native object ownership.
    This endpoint is only available in Netbox 4.5 and later.

.PARAMETER Name
    The name of the owner (required, must be unique).

.PARAMETER Group
    The owner group ID to associate this owner with.

.PARAMETER Description
    A description of the owner.

.PARAMETER User_Groups
    Array of group IDs to associate with this owner.

.PARAMETER Users
    Array of user IDs to associate with this owner.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBOwner -Name "Network Operations"

.EXAMPLE
    New-NBOwner -Name "Data Center Team" -Description "Responsible for DC infrastructure" -Users 1, 2, 3

.EXAMPLE
    New-NBOwner -Name "Cloud Team" -Group 1 -User_Groups 5, 6

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBOwner {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [uint64]$Group,

        [string]$Description,

        [uint64[]]$User_Groups,

        [uint64[]]$Users,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'owners'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Owner')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
