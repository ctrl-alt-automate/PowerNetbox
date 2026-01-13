<#
.SYNOPSIS
    Exits the current branch context.

.DESCRIPTION
    Pops the current branch from the context stack and returns to the
    previous branch or main context. This is the counterpart to Enter-NBBranch.

.OUTPUTS
    [string] Returns the name of the branch that was exited.

.EXAMPLE
    Exit-NBBranch
    Exit the current branch context.

.EXAMPLE
    $exitedBranch = Exit-NBBranch
    Exit and capture the name of the exited branch.

.LINK
    Enter-NBBranch
    Get-NBBranchContext
#>
function Exit-NBBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (-not $script:NetboxConfig.BranchStack -or $script:NetboxConfig.BranchStack.Count -eq 0) {
        Write-Warning "Not currently in a branch context"
        return $null
    }

    $exitedContext = $script:NetboxConfig.BranchStack.Pop()

    # Handle both old string format and new object format
    $branchName = if ($exitedContext -is [PSCustomObject] -and $exitedContext.Name) {
        $exitedContext.Name
    } else {
        $exitedContext
    }

    Write-Verbose "Exited branch '$branchName' (stack depth: $($script:NetboxConfig.BranchStack.Count))"

    return $branchName
}
