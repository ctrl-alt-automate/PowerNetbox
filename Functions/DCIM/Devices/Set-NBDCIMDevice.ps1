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
    The name of the device. Required for single device creation.

.PARAMETER Description
    The new description for the device.

.PARAMETER Role
    The device role ID or name. Required for single device creation.
    Alias: Device_Role (backwards compatibility with Netbox 3.x)

.PARAMETER Device_Type
    The device type ID. Required for single device creation.



.PARAMETER Tenant
    The tenant ID.

.PARAMETER Platform
    The platform ID.

.PARAMETER Serial
    The device serial number.

.PARAMETER Asset_Tag
    The device asset tag.

.PARAMETER Site
    The site ID. Required for single device creation.

.PARAMETER Location
    The location ID.

.PARAMETER Rack
    The rack ID.

.PARAMETER Postiton
    The position within the rack (Valid range: 0.5-100).

.PARAMETER Face
    The rack face (front or rear).

.PARAMETER Latitude
    The latitude coordinate for the device's location.

.PARAMETER Longitude
    The longitude coordinate for the device's location.

.PARAMETER Status
    The device status. Optional for single device creation.
    Valid values: offline, active, planned, staged, failed, inventory, decommissioning
    Default: active

.PARAMETER Airflow
    The device airflow direction.
    Valid values: front-to-rear, rear-to-front, left-to-right, right-to-left, side-to-rear, rear-to-side, bottom-to-top, top-to-bottom,passive, mixed

.PARAMETER Primary_IP4
    The primary IPv4 address ID.

.PARAMETER Primary_IP6
    The primary IPv6 address ID.

.PARAMETER OOB_IP.
    The out-of-band management IP address ID.

.PARAMETER Cluster
    The cluster ID.

.PARAMETER Virtual_Chassis
    The virtual chassis ID.

.PARAMETER VC_Position
    The virtual chassis position.

.PARAMETER VC_Priority
    The virtual chassis priority.

.PARAMETER Description
    A description of the device.

.PARAMETER Comments
    Additional comments about the device.

.PARAMETER Config_template
    The configuration template ID to associate with the device.

.PARAMETER Local_Context_Data
    The local context data for the device.

.PARAMETER Tags
    An array of tag names or IDs to assign to the device.

.PARAMETER Custom_Fields
    A hashtable of custom field values, where keys are field names and values are the corresponding values.

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
    Set-NBDCIMDevice -Id 123 -Status "active"

    Updates device 123 to active status.

.EXAMPLE
    Get-NBDCIMDevice -Status "planned" | ForEach-Object {
        [PSCustomObject]@{Id = $_.id; Status = "active"}
    } | Set-NBDCIMDevice -Force

    Bulk update all planned devices to active status.

.EXAMPLE
    $updates = @(
        [PSCustomObject]@{Id = 100; Status = "active"; Comments = "Deployed"}
        [PSCustomObject]@{Id = 101; Status = "active"; Comments = "Deployed"}
    )
    $updates | Set-NBDCIMDevice -BatchSize 50 -Force

    Bulk update multiple devices with different values.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function Set-NBDCIMDevice {
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
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [Alias('Device_Role')]
        [object]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [object]$Device_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Site,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'inventory', 'decommissioning', IgnoreCase = $true)]
        [string]$Status,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('front-to-rear', 'rear-to-front', 'left-to-right', 'right-to-left', 'side-to-rear', 'rear-to-side', 'bottom-to-top', 'top-to-bottom','passive','mixed','', IgnoreCase = $true)]
        [string]$Airflow,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Platform,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Cluster,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Rack,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[double]]$Position,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('front', 'rear', IgnoreCase = $true)]
        [string]$Face,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[double]]$Latitude,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[double]]$Longitude,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Serial,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Asset_Tag,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Virtual_Chassis,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$VC_Priority,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$VC_Position,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Primary_IP4,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Primary_IP6,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$OOB_IP,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Comments,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Config_Template,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Local_Context_Data,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Owner,

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

        [object[]]$Tags,

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

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'PATCH'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Updating devices'
                }
                $result = Send-NBBulkRequest @bulkParams

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
