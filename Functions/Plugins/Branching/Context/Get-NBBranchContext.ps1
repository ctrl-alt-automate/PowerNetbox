<#
.SYNOPSIS
    Gets the current branch context.

.DESCRIPTION
    Returns the name of the currently active branch context, or $null if
    operating in the main context (not in any branch).

.PARAMETER Stack
    Return the entire branch stack instead of just the current branch.

.OUTPUTS
    [string] The current branch name, or $null if in main context.
    [string[]] If -Stack is specified, returns all branches in the stack.

.EXAMPLE
    Get-NBBranchContext
    Returns the current branch name or $null.

.EXAMPLE
    if (Get-NBBranchContext) { "In branch" } else { "In main" }
    Check if currently in a branch context.

.EXAMPLE
    Get-NBBranchContext -Stack
    Returns the entire branch stack.

.LINK
    Enter-NBBranch
    Exit-NBBranch
#>
function Get-NBBranchContext {
    Write-Verbose "Retrieving Branch Context"
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch]$Stack
    )

    if (-not $script:NetboxConfig.BranchStack) {
        if ($Stack) {
            return @()
        }
        return $null
    }

    if ($Stack) {
        return $script:NetboxConfig.BranchStack.ToArray()
    }

    if ($script:NetboxConfig.BranchStack.Count -eq 0) {
        return $null
    }

    return $script:NetboxConfig.BranchStack.Peek()
}
