<#
.SYNOPSIS
    Creates a new user in Netbox.

.DESCRIPTION
    Creates a new user in Netbox Users module.

.PARAMETER Username
    Username for the new user.

.PARAMETER Password
    Password for the new user (required). Use SecureString for security.

.PARAMETER First_Name
    First name.

.PARAMETER Last_Name
    Last name.

.PARAMETER Email
    Email address.

.PARAMETER Is_Staff
    Whether user has staff access.
    DEPRECATED: This parameter is removed in Netbox 4.5 and will be ignored.

.PARAMETER Is_Active
    Whether user is active.

.PARAMETER Is_Superuser
    Whether user is a superuser.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    $securePass = ConvertTo-SecureString "SecureP@ss123" -AsPlainText -Force
    New-NBUser -Username "newuser" -Password $securePass

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [securestring]$Password,

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

        # Check for deprecated parameters
        $excludeIsStaff = Test-NBDeprecatedParameter -ParameterName 'Is_Staff' -DeprecatedInVersion '4.5.0' -BoundParameters $PSBoundParameters

        # Convert SecureString to plain text for API (required by Netbox)
        $params = @{}
        foreach ($key in $PSBoundParameters.Keys) {
            if ($key -eq 'Password') {
                $params['password'] = [System.Net.NetworkCredential]::new('', $Password).Password
            }
            elseif ($key -eq 'Is_Staff' -and $excludeIsStaff) {
                # Skip deprecated parameter on Netbox 4.5+
                continue
            }
            elseif ($key -notin 'Raw', 'WhatIf', 'Confirm', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable') {
                $params[$key] = $PSBoundParameters[$key]
            }
        }

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Username, 'Create User')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $params -Raw:$Raw
        }
    }
}
