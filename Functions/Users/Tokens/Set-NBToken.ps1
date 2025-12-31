<#
.SYNOPSIS
    Updates an existing API token in Netbox.

.DESCRIPTION
    Updates an existing API token in Netbox Users module.

.PARAMETER Id
    The ID of the token to update.

.PARAMETER User
    User ID for the token.

.PARAMETER Description
    Description of the token.

.PARAMETER Expires
    Expiration date (datetime).

.PARAMETER Write_Enabled
    Whether write operations are enabled.

.PARAMETER Allowed_Ips
    Array of allowed IP addresses/networks.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBToken -Id 1 -Write_Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Set-NBToken {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$User,

        [string]$Description,

        [datetime]$Expires,

        [bool]$Write_Enabled,

        [string[]]$Allowed_Ips,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Token"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'tokens', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Token')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
