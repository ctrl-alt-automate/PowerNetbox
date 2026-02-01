<#
.SYNOPSIS
    Updates one or more devices in Netbox DCIM module.

.DESCRIPTION
    Updates existing devices in Netbox DCIM module. Supports both single device
    updates with individual parameters and bulk updates via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    devices are sent per API request. Each object must have an Id property.

.PARAMETER Id
    The database ID of the device to update. Required for single updates.

.PARAMETER Name
    The new name for the device.

.PARAMETER Role
    The device role ID.
    Alias: Device_Role (backwards compatibility)

.PARAMETER Device_Type
    The device type ID.

.PARAMETER Site
    The site ID.

.PARAMETER Status
    Status of the device.

.PARAMETER Platform
    The platform ID.

.PARAMETER Tenant
    The tenant ID.

.PARAMETER Cluster
    The cluster ID.

.PARAMETER Rack
    The rack ID.

.PARAMETER Position
    Position in the rack.

.PARAMETER Face
    Face of the device in the rack.

.PARAMETER Serial
    Serial number.

.PARAMETER Asset_Tag
    Asset tag.

.PARAMETER Comments
    Comments about the device.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Owner
    The owner ID for object ownership (Netbox 4.5+ only).

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object MUST have an Id property.

.PARAMETER BatchSize
    Number of devices to update per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDDCIM Device -Id 123 -Status "active"

    Updates device 123 to active status.

.EXAMPLE
    Get-NBDDCIM Device -Status "planned" | ForEach-Object {
        [PSCustomObject]@{Id = $_.id; Status = "active"}
    } | Set-NBDDCIM Device -Force

    Bulk update all planned devices to active status.

.EXAMPLE
    $updates = @(
        [PSCustomObject]@{Id = 100; Status = "active"; Comments = "Deployed"}
        [PSCustomObject]@{Id = 101; Status = "active"; Comments = "Deployed"}
    )
    $updates | Set-NBDDCIM Device -BatchSize 50 -Force

    Bulk update multiple devices with different values.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBDDCIM Device {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [uint64]$Id,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single')]
        [Alias('Device_Role')]
        [object]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [object]$Device_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Site,

        [Parameter(ParameterSetName = 'Single')]
        [object]$Status,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Platform,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Cluster,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Rack,

        [Parameter(ParameterSetName = 'Single')]
        [uint16]$Position,

        [Parameter(ParameterSetName = 'Single')]
        [object]$Face,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Serial,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Asset_Tag,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Virtual_Chassis,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VC_Priority,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VC_Position,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Primary_IP4,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Primary_IP6,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Comments,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Owner,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        # Common parameters
        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Use Id directly - no need to fetch device first (saves an API call per update)
            if ($Force -or $PSCmdlet.ShouldProcess("Device ID $Id", "Update device")) {
                $DeviceSegments = [System.Collections.ArrayList]::new(@('dcim', 'devices', $Id))

                $URIComponents = BuildURIComponents -URISegments $DeviceSegments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

                $DeviceURI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $DeviceURI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                # Validate that Id is present
                $itemId = if ($InputObject.Id) { $InputObject.Id }
                          elseif ($InputObject.id) { $InputObject.id }
                          else { $null }

                if (-not $itemId) {
                    Write-Error "InputObject must have an 'Id' property for bulk updates" -TargetObject $InputObject
                    return
                }

                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $value = $prop.Value

                    # Handle property name mappings
                    switch ($key) {
                        'device_role' { $key = 'role' }
                        'device_type' { $key = 'device_type' }
                        'asset_tag' { $key = 'asset_tag' }
                        'virtual_chassis' { $key = 'virtual_chassis' }
                        'vc_priority' { $key = 'vc_priority' }
                        'vc_position' { $key = 'vc_position' }
                        'primary_ip4' { $key = 'primary_ip4' }
                        'primary_ip6' { $key = 'primary_ip6' }
                        'custom_fields' { $key = 'custom_fields' }
                    }

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) device(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Update devices (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) devices in bulk PATCH mode with batch size $BatchSize"

                $result = Send-NBBulkRequest -URI $URI -Items $bulkItems.ToArray() -Method PATCH `
                    -BatchSize $BatchSize -ShowProgress -ActivityName 'Updating devices'

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to update device: $($failure.Error)" -TargetObject $failure.Item
                }

                # Write summary
                if ($result.HasErrors) {
                    Write-Warning $result.GetSummary()
                }
                else {
                    Write-Verbose $result.GetSummary()
                }
            }
        }
    }
}
