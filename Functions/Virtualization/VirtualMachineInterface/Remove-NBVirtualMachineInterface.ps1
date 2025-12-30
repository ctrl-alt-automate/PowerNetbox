<#
.SYNOPSIS
    Removes a virtual machine interface from Netbox.

.DESCRIPTION
    Removes a virtual machine interface from the Netbox virtualization module.
    Supports pipeline input from Get-NBVVirtual MachineInterface.
    Warning: This will also remove any IP addresses assigned to the interface.

.PARAMETER Id
    The database ID(s) of the interface(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVVirtual MachineInterface -Id 1

    Removes VM interface ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBVVirtual MachineInterface -Id 1, 2, 3 -Force

    Removes multiple interfaces without confirmation.

.EXAMPLE
    Get-NBVVirtual MachineInterface -Virtual_Machine_Id 5 | Remove-NBVVirtual MachineInterface -Force

    Removes all interfaces from VM ID 5 via pipeline.

.EXAMPLE
    Get-NBVVirtual Machine -Name "test-vm" | Get-NBVVirtual MachineInterface | Remove-NBVVirtual MachineInterface

    Removes all interfaces from a VM found by name.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/vminterface/
#>
function Remove-NBVVirtual MachineInterface {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Virtual Machine Interface"
        foreach ($InterfaceId in $Id) {
            $CurrentInterface = Get-NBVVirtual MachineInterface -Id $InterfaceId -ErrorAction Stop

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces', $CurrentInterface.Id))

            $URI = BuildNewURI -Segments $Segments

            # Build descriptive target for confirmation
            $Target = "$($CurrentInterface.Name)"
            if ($CurrentInterface.Virtual_Machine) {
                $Target = "Interface '$($CurrentInterface.Name)' on VM '$($CurrentInterface.Virtual_Machine.Name)'"
            }

            if ($Force -or $PSCmdlet.ShouldProcess($Target, 'Delete interface')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
