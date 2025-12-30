<#
.SYNOPSIS
    Creates a new cable connection between two device interfaces in Netbox.

.DESCRIPTION
    Creates a new cable connection between two device interfaces in the Netbox DCIM module.
    This function New-NBDCIMInterfaceConnection {
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
        $null = Get-NBDDCIM Interface -Id $Interface_A -ErrorAction Stop

        Write-Verbose "Validating Interface B (ID: $Interface_B) exists..."
        $null = Get-NBDDCIM Interface -Id $Interface_B -ErrorAction Stop

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Interface $Interface_A <-> Interface $Interface_B", 'Create connection')) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST
        }
    }
}
