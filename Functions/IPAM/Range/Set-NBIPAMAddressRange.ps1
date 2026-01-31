<#
.SYNOPSIS
    Updates an existing PAMAddressRange in Netbox I module.

.DESCRIPTION
    Updates an existing PAMAddressRange in Netbox I module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBIPAMAddressRange

    Returns all PAMAddressRange objects.

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

        [object]$Status,

        [uint64]$Tenant,

        [uint64]$VRF,

        [object]$Role,

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

            if ($Force -or $PSCmdlet.ShouldProcess("IP Range ID $RangeID", 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method
            }
        }
    }
}
