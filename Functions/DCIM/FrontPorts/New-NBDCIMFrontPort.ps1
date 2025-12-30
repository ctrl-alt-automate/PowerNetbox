<#
.SYNOPSIS
    Creates a new front port on a device in Netbox.

.DESCRIPTION
    Creates a new front port on a specified device in the Netbox DCIM module.
    Front ports represent the front-facing ports on patch panels or other devices
    that connect to rear ports for pass-through cabling.

.PARAMETER Device
    The database ID of the device to add the front port to.

.PARAMETER Name
    The name of the front port (e.g., 'Port 1', 'Front-01').

.PARAMETER Type
    The connector type of the front port. Common types include:
    - Copper: '8p8c' (RJ-45), '8p6c', '8p4c', '110-punch', 'bnc'
    - Fiber: 'lc', 'lc-apc', 'sc', 'sc-apc', 'st', 'mpo', 'mtrj'
    - Coax: 'f', 'n', 'bnc'
    - Other: 'splice', 'other'

.PARAMETER Rear_Port
    The database ID of the rear port that this front port maps to.
    Required for establishing the pass-through connection.

.PARAMETER Module
    The database ID of the module within the device (for modular devices).

.PARAMETER Label
    A physical label for the port (what's printed on the device).

.PARAMETER Color
    The color of the port in 6-character hex format (e.g., 'ff0000' for red).

.PARAMETER Rear_Port_Position
    The position on the rear port (for rear ports with multiple positions).
    Defaults to 1 if not specified.

.PARAMETER Description
    A description of the front port.

.PARAMETER Mark_Connected
    Whether to mark this port as connected even without a cable object.

.PARAMETER Tags
    Array of tag IDs to assign to this front port.

.EXAMPLE
    New-NBDCIMFrontPort -Device 42 -Name "Port 1" -Type "8p8c" -Rear_Port 100

    Creates a new RJ-45 front port named 'Port 1' on device 42, mapped to rear port 100.

.EXAMPLE
    New-NBDCIMFrontPort -Device 42 -Name "Fiber-01" -Type "lc" -Rear_Port 100 -Color "00ff00"

    Creates a new LC fiber front port with a green color indicator.

.EXAMPLE
    1..24 | ForEach-Object {
        New-NBDCIMFrontPort -Device 42 -Name "Port $_" -Type "8p8c" -Rear_Port (100 + $_)
    }

    Creates 24 front ports on a patch panel, each mapped to a corresponding rear port.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/frontport/
#>
function New-NBDCIMFrontPort {
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

        [Parameter(Mandatory = $true)]
        [uint64]$Rear_Port,

        [uint64]$Module,

        [string]$Label,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [ValidateRange(1, 1024)]
        [uint16]$Rear_Port_Position,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags
    )

    process {
        Write-Verbose "Creating D CI MF ro nt Po rt"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Device $Device", "Create front port '$Name'")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}
