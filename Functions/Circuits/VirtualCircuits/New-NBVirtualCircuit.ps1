<#
.SYNOPSIS
    Creates a new virtual circuit in Netbox.

.DESCRIPTION
    Creates a new virtual circuit in Netbox.

.PARAMETER Cid
    Circuit ID string.

.PARAMETER Provider_Network
    Provider network ID.

.PARAMETER Provider_Account
    Provider account ID.

.PARAMETER Type
    Virtual circuit type ID.

.PARAMETER Status
    Status (planned, provisioning, active, offline, deprovisioning, decommissioned).

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    New-NBVirtualCircuit -Cid "VC-001" -Provider_Network 1 -Type 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBVirtualCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Cid,

        [Parameter(Mandatory = $true)]
        [uint64]$Provider_Network,

        [uint64]$Provider_Account,

        [Parameter(Mandatory = $true)]
        [uint64]$Type,

        [ValidateSet('planned', 'provisioning', 'active', 'offline', 'deprovisioning', 'decommissioned')]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuits'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Cid, 'Create Virtual Circuit')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
