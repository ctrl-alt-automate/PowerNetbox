<#
.SYNOPSIS
    Updates an existing CIMDevice in Netbox D module.

.DESCRIPTION
    Updates an existing CIMDevice in Netbox D module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMDevice

    Returns all CIMDevice objects.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBDCIMDevice {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [string]$Name,

        [Alias('Device_Role')]
        [object]$Role,

        [object]$Device_Type,

        [uint64]$Site,

        [object]$Status,

        [uint64]$Platform,

        [uint64]$Tenant,

        [uint64]$Cluster,

        [uint64]$Rack,

        [uint16]$Position,

        [object]$Face,

        [string]$Serial,

        [string]$Asset_Tag,

        [uint64]$Virtual_Chassis,

        [uint64]$VC_Priority,

        [uint64]$VC_Position,

        [uint64]$Primary_IP4,

        [uint64]$Primary_IP6,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($DeviceID in $Id) {
            $CurrentDevice = Get-NBDCIMDevice -Id $DeviceID -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("$($CurrentDevice.Name)", "Set")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices', $CurrentDevice.Id))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }

    end {

    }
}
