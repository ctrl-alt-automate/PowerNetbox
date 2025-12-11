<#
.SYNOPSIS
    Creates a new rear port on a device in Netbox.

.DESCRIPTION
    Creates a new rear port on a specified device in the Netbox DCIM module.
    Rear ports represent the back-facing ports on patch panels or other devices
    that connect to front ports for pass-through cabling.

.PARAMETER Device
    The database ID of the device to add the rear port to.

.PARAMETER Name
    The name of the rear port (e.g., 'Rear 1', 'Back-01').

.PARAMETER Type
    The connector type of the rear port. Common types include:
    - Copper: '8p8c' (RJ-45), '8p6c', '8p4c', '110-punch', 'bnc'
    - Fiber: 'lc', 'lc-apc', 'sc', 'sc-apc', 'st', 'mpo', 'mtrj'
    - Coax: 'f', 'n', 'bnc'
    - Other: 'splice', 'other'

.PARAMETER Module
    The database ID of the module within the device (for modular devices).

.PARAMETER Label
    A physical label for the port (what's printed on the device).

.PARAMETER Color
    The color of the port in 6-character hex format (e.g., 'ff0000' for red).

.PARAMETER Positions
    The number of front port positions this rear port supports.
    Defaults to 1. Use higher values for multi-position rear ports.

.PARAMETER Description
    A description of the rear port.

.PARAMETER Mark_Connected
    Whether to mark this port as connected even without a cable object.

.PARAMETER Tags
    Array of tag IDs to assign to this rear port.

.EXAMPLE
    New-NBDCIMRearPort -Device 42 -Name "Rear 1" -Type "8p8c"

    Creates a new RJ-45 rear port named 'Rear 1' on device 42.

.EXAMPLE
    New-NBDCIMRearPort -Device 42 -Name "Fiber-Rear-01" -Type "lc" -Positions 2

    Creates a new LC fiber rear port that supports 2 front port positions.

.EXAMPLE
    1..24 | ForEach-Object {
        New-NBDCIMRearPort -Device 42 -Name "Rear $_" -Type "8p8c"
    }

    Creates 24 rear ports on a patch panel.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/rearport/
#>
function New-NBDCIMRearPort {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('8p8c', '8p6c', '8p4c', '8p2c', '6p6c', '6p4c', '6p2c', '4p4c', '4p2c',
            'gg45', 'tera-4p', 'tera-2p', 'tera-1p', '110-punch', 'bnc', 'f', 'n', 'mrj21',
            'fc', 'lc', 'lc-pc', 'lc-upc', 'lc-apc', 'lsh', 'lsh-pc', 'lsh-upc', 'lsh-apc',
            'lx5', 'lx5-pc', 'lx5-upc', 'lx5-apc', 'mpo', 'mtrj', 'sc', 'sc-pc', 'sc-upc',
            'sc-apc', 'st', 'cs', 'sn', 'sma-905', 'sma-906', 'urm-p2', 'urm-p4', 'urm-p8',
            'splice', 'other', IgnoreCase = $true)]
        [string]$Type,

        [uint64]$Module,

        [string]$Label,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [ValidateRange(1, 1024)]
        [uint16]$Positions = 1,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Device $Device", "Create rear port '$Name'")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}
