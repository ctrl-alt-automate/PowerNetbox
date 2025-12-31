<#
.SYNOPSIS
    Creates a new group in Netbox.

.DESCRIPTION
    Creates a new group in Netbox Users module.

.PARAMETER Name
    Name of the group.

.PARAMETER Permissions
    Array of permission IDs.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBGroup -Name "Network Admins"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [uint64[]]$Permissions,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Group"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
