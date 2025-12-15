<#
.SYNOPSIS
    Executes a script block within a branch context.

.DESCRIPTION
    Temporarily enters a branch context, executes the provided script block,
    and then automatically exits the branch context. This provides exception-safe
    branch handling similar to using Push-Location/Pop-Location with try/finally.

    The branch context is always restored even if an error occurs in the script block.

.PARAMETER Branch
    The name of the branch to execute within.

.PARAMETER ScriptBlock
    The script block to execute within the branch context.

.OUTPUTS
    [object] Returns whatever the script block returns.

.EXAMPLE
    Invoke-NBInBranch -Branch "feature/test" -ScriptBlock {
        New-NBDCIMDevice -Name "test-server" -DeviceType 1 -Site 1
    }
    Create a device within a branch.

.EXAMPLE
    $results = Invoke-NBInBranch -Branch "staging" -ScriptBlock {
        Get-NBDCIMDevice -Status "planned"
        Get-NBIPAMAddress -Status "reserved"
    }
    Execute multiple operations and capture results.

.LINK
    Enter-NBBranch
    Exit-NBBranch
#>
function Invoke-NBInBranch {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Branch,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock
    )

    Enter-NBBranch -Name $Branch

    try {
        # Execute the script block and return its output
        . $ScriptBlock
    }
    finally {
        # Always restore context, even on error
        $null = Exit-NBBranch
    }
}
