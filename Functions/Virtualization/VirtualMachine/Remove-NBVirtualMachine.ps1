
function Remove-NBVirtualMachine {
<#
    .SYNOPSIS
        Delete a virtual machine

    .DESCRIPTION
        Deletes a virtual machine from Netbox by ID

    .PARAMETER Id
        Database ID of the virtual machine

    .PARAMETER Force
        Force deletion without any prompts

    .EXAMPLE
        PS C:\> Remove-NBVirtualMachine -Id $value1

    .NOTES
        Additional information about the function.
#>

    [CmdletBinding(ConfirmImpact = 'High',
                   SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force
    )

    begin {

    }

    process {
        foreach ($VMId in $Id) {
            $CurrentVM = Get-NBVirtualMachine -Id $VMId -ErrorAction Stop

            if ($Force -or $pscmdlet.ShouldProcess("$($CurrentVM.Name)/$($CurrentVM.Id)", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines', $CurrentVM.Id))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE
            }
        }
    }

    end {

    }
}