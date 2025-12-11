<#
.SYNOPSIS
    Creates a new network interface on a virtual machine in Netbox.

.DESCRIPTION
    Creates a new network interface on a specified virtual machine in the Netbox
    Virtualization module. VM interfaces are used to assign IP addresses and
    configure network connectivity for virtual machines.

.PARAMETER Name
    The name of the interface (e.g., 'eth0', 'ens192', 'Ethernet0').

.PARAMETER Virtual_Machine
    The database ID of the virtual machine to add the interface to.

.PARAMETER Enabled
    Whether the interface is enabled. Defaults to $true if not specified.

.PARAMETER MAC_Address
    The MAC address of the interface in format XX:XX:XX:XX:XX:XX.
    Accepts both uppercase and lowercase hex characters.

.PARAMETER MTU
    Maximum Transmission Unit size. Common values:
    - 1500 for standard Ethernet
    - 9000 for jumbo frames
    Valid range: 1-65535

.PARAMETER Description
    A description of the interface.

.PARAMETER Mode
    VLAN mode for the interface:
    - 'access' - Untagged access port
    - 'tagged' - Trunk port with tagged VLANs
    - 'tagged-all' - Trunk port allowing all VLANs

.PARAMETER Untagged_VLAN
    The database ID of the untagged/native VLAN.

.PARAMETER Tagged_VLANs
    Array of database IDs for tagged VLANs (for trunk ports).

.PARAMETER VRF
    The database ID of the VRF for this interface.

.PARAMETER Tags
    Array of tag IDs to assign to this interface.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualMachineInterface -Name "eth0" -Virtual_Machine 42

    Creates a new enabled interface named 'eth0' on VM ID 42.

.EXAMPLE
    New-NBVirtualMachineInterface -Name "ens192" -Virtual_Machine 42 -MAC_Address "00:50:56:AB:CD:EF"

    Creates a new interface with a specific MAC address.

.EXAMPLE
    $vm = Get-NBVirtualMachine -Name "webserver01"
    New-NBVirtualMachineInterface -Name "eth0" -Virtual_Machine $vm.Id -MTU 9000

    Creates a new interface with jumbo frame support on a VM found by name.

.EXAMPLE
    New-NBVirtualMachineInterface -Name "eth0" -Virtual_Machine 42 -Mode "tagged" -Tagged_VLANs 10,20,30

    Creates a trunk interface with multiple tagged VLANs.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/vminterface/
#>
function New-NBVirtualMachineInterface {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint64]$Virtual_Machine,

        [bool]$Enabled = $true,

        [ValidatePattern('^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$')]
        [string]$MAC_Address,

        [ValidateRange(1, 65535)]
        [uint16]$MTU,

        [string]$Description,

        [ValidateSet('access', 'tagged', 'tagged-all', IgnoreCase = $true)]
        [string]$Mode,

        [uint64]$Untagged_VLAN,

        [uint64[]]$Tagged_VLANs,

        [uint64]$VRF,

        [uint64[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces'))

        # Ensure Enabled is always included in the body (defaults to true)
        $PSBoundParameters['Enabled'] = $Enabled

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("VM $Virtual_Machine", "Create interface '$Name'")) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
