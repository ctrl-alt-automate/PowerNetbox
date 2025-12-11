<#
.SYNOPSIS
    Creates a new interface on a device in Netbox.

.DESCRIPTION
    Creates a new network interface on a specified device in the Netbox DCIM module.
    Supports various interface types including physical, virtual, LAG, and wireless interfaces.

.PARAMETER Device
    The database ID of the device to add the interface to.

.PARAMETER Name
    The name of the interface (e.g., 'eth0', 'GigabitEthernet0/1').

.PARAMETER Type
    The interface type. Supports physical types (1000base-t, 10gbase-x-sfpp, etc.),
    virtual types (virtual, bridge, lag), and wireless types (ieee802.11ac, etc.).

.PARAMETER Enabled
    Whether the interface is enabled. Defaults to true if not specified.

.PARAMETER Form_Factor
    Legacy parameter for interface form factor.

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

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "eth0" -Type "1000base-t"

    Creates a new 1GbE interface named 'eth0' on device ID 42.

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "bond0" -Type "lag" -Description "Server uplink LAG"

    Creates a new LAG interface for link aggregation.

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "Gi0/1" -Type "1000base-t" -Mode "Tagged" -Tagged_VLANs 10,20,30

    Creates a trunk interface with multiple tagged VLANs.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/interface/
#>
function New-NBDCIMInterface {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateSet('virtual', 'bridge', 'lag', '100base-tx', '1000base-t', '2.5gbase-t', '5gbase-t', '10gbase-t', '10gbase-cx4', '1000base-x-gbic', '1000base-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '200gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cpak', '100gbase-x-qsfp28', '200gbase-x-qsfp56', '400gbase-x-qsfpdd', '400gbase-x-osfp', '1000base-kx', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.15.1', 'other-wireless', 'gsm', 'cdma', 'lte', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '64gfc-qsfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', 'epon', '10g-epon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [bool]$Enabled,

        [object]$Form_Factor,

        [ValidateRange(1, 65535)]
        [uint16]$MTU,

        [ValidatePattern('^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$')]
        [string]$MAC_Address,

        [bool]$MGMT_Only,

        [uint64]$LAG,

        [string]$Description,

        [ValidateSet('Access', 'Tagged', 'Tagged All', '100', '200', '300', IgnoreCase = $true)]
        [string]$Mode,

        [ValidateRange(1, 4094)]
        [uint16]$Untagged_VLAN,

        [ValidateRange(1, 4094)]
        [uint16[]]$Tagged_VLANs
    )

    process {
        # Convert Mode friendly names to API values
        if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
            $PSBoundParameters.Mode = switch ($Mode) {
                'Access' { 100 }
                'Tagged' { 200 }
                'Tagged All' { 300 }
                default { $_ }
            }
        }

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Device $Device", "Create interface '$Name'")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}
