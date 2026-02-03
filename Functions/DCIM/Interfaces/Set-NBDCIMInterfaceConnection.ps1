
function Set-NBDCIMInterfaceConnection {
<#
    .SYNOPSIS
        Update an interface connection

    .DESCRIPTION
        Update an interface connection

    .PARAMETER Id
        Database ID of the interface connection to update.

    .PARAMETER Connection_Status
        Status of the connection (e.g., 'connected', 'planned').

    .PARAMETER Interface_A
        Database ID of the first interface in the connection.

    .PARAMETER Interface_B
        Database ID of the second interface in the connection.

    .PARAMETER Force
        Skip confirmation prompts.

    .EXAMPLE
        PS C:\> Set-NBDCIMInterfaceConnection -Id 1 -Connection_Status 'connected'
#>

    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [ValidateSet('connected', 'planned', 'decommissioning', IgnoreCase = $true)]
        [string]$Connection_Status,

        [uint64]$Interface_A,

        [uint64]$Interface_B,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        if ((@($ID).Count -gt 1) -and ($Interface_A -or $Interface_B)) {
            throw "Cannot set multiple connections to the same interface"
        }
    }

    process {
        Write-Verbose "Updating DCIM Interface Connection"
        foreach ($ConnectionID in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections', $ConnectionID))

            if ($Force -or $pscmdlet.ShouldProcess("Interface Connection ID $ConnectionID", "Set")) {

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }

    end {

    }
}
