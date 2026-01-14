function Remove-NBDCIMInterface {
    <#
    .SYNOPSIS
        Removes an interface

    .DESCRIPTION
        Removes an interface by ID from a device

    .PARAMETER Id
        Database ID of the interface to delete.

    .PARAMETER Force
        Skip confirmation prompts.

    .EXAMPLE
        PS C:\> Remove-NBDCIMInterface -Id 123
#>

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        Write-Verbose "Removing D CI MI nt er fa ce"
        foreach ($InterfaceId in $Id) {
            $CurrentInterface = Get-NBDCIMInterface -Id $InterfaceId -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("Name: $($CurrentInterface.Name) | ID: $($CurrentInterface.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces', $CurrentInterface.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}
