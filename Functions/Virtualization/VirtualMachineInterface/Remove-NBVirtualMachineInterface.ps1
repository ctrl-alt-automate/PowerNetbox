<#
.SYNOPSIS
    Removes a virtual machine interface from Netbox.

.DESCRIPTION
    Removes a virtual machine interface from the Netbox virtualization module.
    Supports pipeline input from Get-NBVirtualMachineInterface.
    Warning: This will also remove any IP addresses assigned to the interface.

.PARAMETER Id
    The database ID(s) of the interface(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualMachineInterface -Id 1

    Removes VM interface ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBVirtualMachineInterface -Id 1, 2, 3 -Force

    Removes multiple interfaces without confirmation.

.EXAMPLE
    Get-NBVirtualMachineInterface -Virtual_Machine_Id 5 | Remove-NBVirtualMachineInterface -Force

    Removes all interfaces from VM ID 5 via pipeline.

.EXAMPLE
    Get-NBVirtualMachine -Name "test-vm" | Get-NBVirtualMachineInterface | Remove-NBVirtualMachineInterface

    Removes all interfaces from a VM found by name.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/vminterface/
#>
function Remove-NBVirtualMachineInterface {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Virtual Machine Interface"
        foreach ($InterfaceId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces', $InterfaceId))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("VM Interface ID $InterfaceId", 'Delete interface')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
