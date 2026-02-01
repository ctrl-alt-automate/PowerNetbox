<#
.SYNOPSIS
    Creates a new cable connection between two device interfaces in Netbox.

.DESCRIPTION
    Creates a new cable connection between two device interfaces in the Netbox DCIM module.
    This function validates that both interfaces exist before attempting to create the connection.
    The connection is represented as a cable object linking Interface A to Interface B.

.PARAMETER Interface_A
    The database ID of the first interface (A-side of the connection).
    The interface must exist in Netbox or the function will throw an error.

.PARAMETER Interface_B
    The database ID of the second interface (B-side of the connection).
    The interface must exist in Netbox or the function will throw an error.

.PARAMETER Connection_Status
    The status of the connection. Common values include:
    - 'connected' - The connection is active
    - 'planned' - The connection is planned but not yet implemented

.EXAMPLE
    New-NBDCIMInterfaceConnection -Interface_A 101 -Interface_B 102

    Creates a new connection between interface ID 101 and interface ID 102.

.EXAMPLE
    New-NBDCIMInterfaceConnection -Interface_A 101 -Interface_B 102 -Connection_Status 'planned'

    Creates a planned connection between two interfaces.

.EXAMPLE
    $intA = Get-NBDCIMInterface -Device_Id 1 -Name 'eth0'
    $intB = Get-NBDCIMInterface -Device_Id 2 -Name 'eth0'
    New-NBDCIMInterfaceConnection -Interface_A $intA.Id -Interface_B $intB.Id

    Creates a connection between eth0 interfaces on two different devices.

.NOTES
    This function creates a cable object in Netbox. The interface-connections endpoint
    is a legacy endpoint that may be deprecated in future Netbox versions.
    Consider using the cables endpoint directly for new implementations.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/cable/
#>
function New-NBDCIMInterfaceConnection {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Interface_A,

        [Parameter(Mandatory = $true)]
        [uint64]$Interface_B,

        [ValidateSet('connected', 'planned', IgnoreCase = $true)]
        [string]$Connection_Status
    )

    process {
        # Verify both interfaces exist before creating connection
        Write-Verbose "Validating Interface A (ID: $Interface_A) exists..."
        $null = Get-NBDCIMInterface -Id $Interface_A -ErrorAction Stop

        Write-Verbose "Validating Interface B (ID: $Interface_B) exists..."
        $null = Get-NBDCIMInterface -Id $Interface_B -ErrorAction Stop

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Interface $Interface_A <-> Interface $Interface_B", 'Create connection')) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}
