
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
        PS C:\> Set-NBDDCIM InterfaceConnection -Id 1 -Connection_Status 'connected'
#>

    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [object]$Connection_Status,

        [uint64]$Interface_A,

        [uint64]$Interface_B,

        [switch]$Force
    )

    begin {
        if ((@($ID).Count -gt 1) -and ($Interface_A -or $Interface_B)) {
            throw "Cannot set multiple connections to the same interface"
        }
    }

    process {
        Write-Verbose "Updating DCIM Interface Co nn ec ti on"
        foreach ($ConnectionID in $Id) {
            $CurrentConnection = Get-NBDDCIM InterfaceConnection -Id $ConnectionID -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interface-connections', $CurrentConnection.Id))

            if ($Force -or $pscmdlet.ShouldProcess("Connection ID $($CurrentConnection.Id)", "Set")) {

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH
            }
        }
    }

    end {

    }
}
