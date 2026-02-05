<#
.SYNOPSIS
    Updates an existing IPAM AddressRange in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM AddressRange in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMAddressRange

    Updates an existing IPAM Address Range object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBIPAMAddressRange {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Start_Address,

        [string]$End_Address,

        [ValidateSet('active', 'reserved', 'deprecated', IgnoreCase = $true)]
        [string]$Status,

        [uint64]$Tenant,

        [uint64]$VRF,

        [uint64]$Role,

        [hashtable]$Custom_Fields,

        [string]$Description,

        [string]$Comments,

        [object[]]$Tags,

        [switch]$Mark_Utilized,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        foreach ($RangeID in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges', $RangeID))

            Write-Verbose "Updating IP range ID $RangeID"

            if ($Force -or $PSCmdlet.ShouldProcess("ID $RangeID", 'Set IP Range')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method -Raw:$Raw
            }
        }
    }
}
