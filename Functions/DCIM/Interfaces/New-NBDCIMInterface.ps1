<#
.SYNOPSIS
    Creates one or more interfaces on devices in Netbox DCIM module.

.DESCRIPTION
    Creates new network interfaces on specified devices. Supports both single interface
    creation with individual parameters and bulk creation via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    interfaces are sent per API request. This significantly improves performance
    when creating many interfaces.

.PARAMETER Device
    The database ID of the device to add the interface to.

.PARAMETER Name
    The name of the interface (e.g., 'eth0', 'GigabitEthernet0/1').

.PARAMETER Type
    The interface type. Supports physical types (1000base-t, 10gbase-x-sfpp, etc.),
    virtual types (virtual, bridge, lag), and wireless types (ieee802.11ac, etc.).

.PARAMETER Enabled
    Whether the interface is enabled. Defaults to true if not specified.

.PARAMETER MTU
    Maximum Transmission Unit size (typically 1500 for Ethernet).

.PARAMETER MAC_Address
    The MAC address of the interface in format XX:XX:XX:XX:XX:XX.

.PARAMETER MGMT_Only
    If true, this interface is used for management traffic only.

.PARAMETER LAG
    The database ID of the LAG interface this interface belongs to.

.PARAMETER Description
    A description of the interface.

.PARAMETER Mode
    VLAN mode: 'Access' (untagged), 'Tagged' (trunk), or 'Tagged All'.

.PARAMETER Untagged_VLAN
    VLAN ID for untagged/native VLAN (1-4094).

.PARAMETER Tagged_VLANs
    Array of VLAN IDs for tagged VLANs (1-4094 each).

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    the required properties: Device, Name, Type.

.PARAMETER BatchSize
    Number of interfaces to create per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "eth0" -Type "1000base-t"

    Creates a new 1GbE interface named 'eth0' on device ID 42.

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "bond0" -Type "lag" -Description "Server uplink LAG"

    Creates a new LAG interface for link aggregation.

.EXAMPLE
    $interfaces = 0..47 | ForEach-Object {
        [PSCustomObject]@{Device=42; Name="eth$_"; Type="1000base-t"}
    }
    $interfaces | New-NBDCIMInterface -BatchSize 50 -Force

    Creates 48 interfaces in bulk using a single API call.

.EXAMPLE
    Import-Csv interfaces.csv | New-NBDCIMInterface -BatchSize 100 -Force

    Bulk import interfaces from CSV file.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/interface/
#>
function New-NBDCIMInterface {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [uint64]$Device,

        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('virtual', 'bridge', 'lag', '100base-tx', '1000base-t', '2.5gbase-t', '5gbase-t', '10gbase-t', '10gbase-cx4', '1000base-x-gbic', '1000base-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '200gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cpak', '100gbase-x-qsfp28', '200gbase-x-qsfp56', '400gbase-x-qsfpdd', '400gbase-x-osfp', '1000base-kx', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.15.1', 'other-wireless', 'gsm', 'cdma', 'lte', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '64gfc-qsfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', 'epon', '10g-epon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 65535)]
        [uint16]$MTU,

        [Parameter(ParameterSetName = 'Single')]
        [ValidatePattern('^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$')]
        [string]$MAC_Address,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$MGMT_Only,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$LAG,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('Access', 'Tagged', 'Tagged All', '100', '200', '300', IgnoreCase = $true)]
        [string]$Mode,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 4094)]
        [uint16]$Untagged_VLAN,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 4094)]
        [uint16[]]$Tagged_VLANs,

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
        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Convert Mode friendly names to API values
            if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
                $PSBoundParameters.Mode = switch ($Mode) {
                    'Access' { 100 }
                    'Tagged' { 200 }
                    'Tagged All' { 300 }
                    default { $_ }
                }
            }

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            if ($PSCmdlet.ShouldProcess("Device $Device", "Create interface '$Name'")) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $value = $prop.Value

                    # Handle property name mappings
                    switch ($key) {
                        'mac_address' { $key = 'mac_address' }
                        'mgmt_only' { $key = 'mgmt_only' }
                        'untagged_vlan' { $key = 'untagged_vlan' }
                        'tagged_vlans' { $key = 'tagged_vlans' }
                    }

                    # Convert Mode friendly names
                    if ($key -eq 'mode' -and $value -is [string]) {
                        $value = switch ($value) {
                            'Access' { 'access' }
                            'Tagged' { 'tagged' }
                            'Tagged All' { 'tagged-all' }
                            default { $value.ToLower() }
                        }
                    }

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) interface(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create interfaces (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) interfaces in bulk mode with batch size $BatchSize"

                $result = Send-NBBulkRequest -URI $URI -Items $bulkItems.ToArray() -Method POST `
                    -BatchSize $BatchSize -ShowProgress -ActivityName 'Creating interfaces'

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create interface: $($failure.Error)" -TargetObject $failure.Item
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
