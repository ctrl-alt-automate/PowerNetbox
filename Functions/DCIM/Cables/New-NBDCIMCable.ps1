<#
.SYNOPSIS
    Creates a new cable in Netbox DCIM module.

.DESCRIPTION
    Creates a new cable connecting two termination points in Netbox.
    Supports connecting interfaces, console ports, power ports, etc.

.PARAMETER A_Terminations
    Array of termination objects for the A side. Each object should have:
    - object_type: The type (e.g., 'dcim.interface', 'dcim.consoleport')
    - object_id: The ID of the object

.PARAMETER B_Terminations
    Array of termination objects for the B side. Same format as A_Terminations.

.PARAMETER Type
    Cable type (e.g., 'cat5', 'cat5e', 'cat6', 'cat6a', 'cat7', 'cat7a', 'cat8',
    'dac-active', 'dac-passive', 'mrj21-trunk', 'coaxial', 'mmf', 'mmf-om1',
    'mmf-om2', 'mmf-om3', 'mmf-om4', 'mmf-om5', 'smf', 'smf-os1', 'smf-os2',
    'aoc', 'power')

.PARAMETER Status
    Cable status: 'connected', 'planned', 'decommissioning'

.PARAMETER Tenant
    Tenant ID

.PARAMETER Label
    Cable label

.PARAMETER Color
    Cable color (hex code without #)

.PARAMETER Length
    Cable length

.PARAMETER Length_Unit
    Length unit: 'm', 'cm', 'ft', 'in'

.PARAMETER Description
    Cable description

.PARAMETER Comments
    Additional comments

.PARAMETER Tags
    Array of tag names or IDs

.PARAMETER Custom_Fields
    Hashtable of custom field values

.PARAMETER Raw
    Return the raw API response

.EXAMPLE
    $termA = @{ object_type = 'dcim.interface'; object_id = 1 }
    $termB = @{ object_type = 'dcim.interface'; object_id = 2 }
    New-NBDCIMCable -A_Terminations @($termA) -B_Terminations @($termB)

.EXAMPLE
    # Connect two interfaces by ID using helper
    New-NBDCIMCable -A_Terminations @(@{object_type='dcim.interface';object_id=10}) `
                    -B_Terminations @(@{object_type='dcim.interface';object_id=20}) `
                    -Type 'cat6' -Status 'connected' -Label 'Patch-001'

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function New-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$A_Terminations,

        [Parameter(Mandatory = $true)]
        [object[]]$B_Terminations,

        [ValidateSet('cat3', 'cat5', 'cat5e', 'cat6', 'cat6a', 'cat7', 'cat7a', 'cat8',
                     'dac-active', 'dac-passive', 'mrj21-trunk', 'coaxial',
                     'mmf', 'mmf-om1', 'mmf-om2', 'mmf-om3', 'mmf-om4', 'mmf-om5',
                     'smf', 'smf-os1', 'smf-os2', 'aoc', 'power', 'usb')]
        [string]$Type,

        [ValidateSet('connected', 'planned', 'decommissioning')]
        [string]$Status = 'connected',

        [uint64]$Tenant,

        [string]$Label,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [decimal]$Length,

        [ValidateSet('m', 'cm', 'ft', 'in', 'km', 'mi')]
        [string]$Length_Unit,

        [string]$Description,

        [string]$Comments,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cables'))

        # Build the body manually since terminations need special handling
        $body = @{
            a_terminations = $A_Terminations
            b_terminations = $B_Terminations
        }

        if ($PSBoundParameters.ContainsKey('Type')) { $body.type = $Type }
        if ($PSBoundParameters.ContainsKey('Status')) { $body.status = $Status }
        if ($PSBoundParameters.ContainsKey('Tenant')) { $body.tenant = $Tenant }
        if ($PSBoundParameters.ContainsKey('Label')) { $body.label = $Label }
        if ($PSBoundParameters.ContainsKey('Color')) { $body.color = $Color }
        if ($PSBoundParameters.ContainsKey('Length')) { $body.length = $Length }
        if ($PSBoundParameters.ContainsKey('Length_Unit')) { $body.length_unit = $Length_Unit }
        if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }
        if ($PSBoundParameters.ContainsKey('Comments')) { $body.comments = $Comments }
        if ($PSBoundParameters.ContainsKey('Tags')) { $body.tags = $Tags }
        if ($PSBoundParameters.ContainsKey('Custom_Fields')) { $body.custom_fields = $Custom_Fields }

        $URI = BuildNewURI -Segments $Segments

        $displayName = if ($Label) { $Label } else { "Cable" }

        if ($PSCmdlet.ShouldProcess($displayName, 'Create cable')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $body -Raw:$Raw
        }
    }
}
