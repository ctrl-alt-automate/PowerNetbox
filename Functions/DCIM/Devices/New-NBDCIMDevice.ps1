<#
.SYNOPSIS
    Creates one or more devices in Netbox DCIM module.

.DESCRIPTION
    Creates a new device in Netbox DCIM module. Supports both single device
    creation with individual parameters and bulk creation via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    devices are sent per API request. This significantly improves performance
    when creating many devices.

.PARAMETER Name
    The name of the device. Required for single device creation.

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

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    the required properties: Name, Role, Device_Type, Site.

.PARAMETER BatchSize
    Number of devices to create per API request in bulk mode.
    Default: 0 (no batching - backwards compatible single-item mode)
    Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Owner
    The owner ID for object ownership (Netbox 4.5+ only).

.EXAMPLE
    New-NBDCIMDevice -Name "server01" -Role 1 -Device_Type 1 -Site 1

    Creates a single device named "server01".

.EXAMPLE
    $devices = @(
        [PSCustomObject]@{Name="srv01"; Role=1; Device_Type=1; Site=1}
        [PSCustomObject]@{Name="srv02"; Role=1; Device_Type=1; Site=1}
    )
    $devices | New-NBDCIMDevice -BatchSize 50

    Creates multiple devices using bulk API operations.

.EXAMPLE
    1..100 | ForEach-Object {
        [PSCustomObject]@{Name="srv$_"; Role=1; Device_Type=1; Site=1}
    } | New-NBDCIMDevice -BatchSize 50 -Force

    Creates 100 devices in 2 bulk API calls, skipping confirmation.

.OUTPUTS
    [PSCustomObject] The created device object(s).
    [BulkOperationResult] When using -BatchSize, returns bulk operation result.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>

function New-NBDCIMDevice {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [Alias('Device_Role')]
        [object]$Role,

        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [object]$Device_Type,

        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [uint64]$Site,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'inventory', 'decommissioning', IgnoreCase = $true)]
        [string]$Status = 'active',

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('front-to-rear', 'rear-to-front', 'left-to-right', 'right-to-left', 'side-to-rear', 'rear-to-side', 'bottom-to-top', 'top-to-bottom','passive','mixed', IgnoreCase = $true)]
        [string]$Airflow,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Platform,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Cluster,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Location,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Rack,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(0.5, 100)]
        [double]$Position,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('front', 'rear', IgnoreCase = $true)]
        [string]$Face,

        [Parameter(ParameterSetName = 'Single')]
        [double]$Latitude,

        [Parameter(ParameterSetName = 'Single')]
        [double]$Longitude,

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
        [uint64]$OOB_ID,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Comments,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Config_Template,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Local_Context_Data,

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

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Force,

        # Common parameters
        [Parameter()]

        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))
        $URI = BuildNewURI -Segments $Segments

        # For bulk mode, collect items
        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Original single-item behavior
            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            if ($PSCmdlet.ShouldProcess($Name, 'Create new Device')) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                # Convert PSCustomObject to hashtable with lowercase keys for API
                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    # Handle Device_Role alias
                    if ($key -eq 'device_role') {
                        $key = 'role'
                    }
                    $item[$key] = $prop.Value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) device(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create devices (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) devices in bulk mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'POST'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Creating devices'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create device: $($failure.Error)" -TargetObject $failure.Item
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
