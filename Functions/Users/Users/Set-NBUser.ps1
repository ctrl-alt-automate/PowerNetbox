<#
.SYNOPSIS
    Updates an existing user in Netbox.

.DESCRIPTION
    Updates an existing user in Netbox Users module.

.PARAMETER Id
    The ID of the user to update.

.PARAMETER Username
    Username.

.PARAMETER Password
    Password.

.PARAMETER First_Name
    First name.

.PARAMETER Last_Name
    Last name.

.PARAMETER Email
    Email address.

.PARAMETER Is_Staff
    Whether user has staff access.

.PARAMETER Is_Active
    Whether user is active.

.PARAMETER Is_Superuser
    Whether user is a superuser.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBUser -Id 1 -Is_Active $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Username,

        [string]$Password,

        [string]$First_Name,

        [string]$Last_Name,

        [string]$Email,

        [bool]$Is_Staff,

        [bool]$Is_Active,

        [bool]$Is_Superuser,

        [uint64[]]$Groups,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('users', 'users', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update User')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
