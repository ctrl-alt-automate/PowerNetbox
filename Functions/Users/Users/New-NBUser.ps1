<#
.SYNOPSIS
    Creates a new user in Netbox.

.DESCRIPTION
    Creates a new user in Netbox Users module.

.PARAMETER Username
    Username for the new user.

.PARAMETER Password
    Password for the new user.

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
    New-NBUser -Username "newuser" -Password "SecureP@ss123"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
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
        $Segments = [System.Collections.ArrayList]::new(@('users', 'users'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Username, 'Create User')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
