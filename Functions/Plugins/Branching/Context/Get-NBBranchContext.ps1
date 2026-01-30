<#
.SYNOPSIS
    Gets the current branch context.

.DESCRIPTION
    Returns the name of the currently active branch context, or $null if
    operating in the main context (not in any branch).

.PARAMETER Stack
    Return the entire branch stack instead of just the current branch.

.PARAMETER Full
    Return the full branch context object(s) including Name, SchemaId, and Id.

.OUTPUTS
    [string] The current branch name, or $null if in main context.
    [string[]] If -Stack is specified, returns all branch names in the stack.
    [PSCustomObject] If -Full is specified, returns the current branch context object.
    [PSCustomObject[]] If -Stack and -Full are specified, returns all context objects.

.EXAMPLE
    Get-NBBranchContext
    Returns the current branch name or $null.

.EXAMPLE
    if (Get-NBBranchContext) { "In branch" } else { "In main" }
    Check if currently in a branch context.

.EXAMPLE
    Get-NBBranchContext -Stack
    Returns all branch names in the stack.

.EXAMPLE
    Get-NBBranchContext -Full
    Returns the full context object with Name, SchemaId, and Id.

.LINK
    Enter-NBBranch
    Exit-NBBranch
#>
function Get-NBBranchContext {
    [CmdletBinding()]
    [OutputType([string], [string[]], [PSCustomObject], [PSCustomObject[]])]
    param(
        [switch]$Brief,

        [string[]]$Fields,

        [switch]$Stack,
        [switch]$Full
    )

    if (-not $script:NetboxConfig.BranchStack -or $script:NetboxConfig.BranchStack.Count -eq 0) {
        if ($Stack) {
            if ($Full) {
                return [PSCustomObject[]]@()
            }
            return [string[]]@()
        }
        return $null
    }

    if ($Stack) {
        $items = $script:NetboxConfig.BranchStack.ToArray()
        if ($Full) {
            return [PSCustomObject[]]$items
        }
        # Return just the names for backwards compatibility
        return [string[]]($items | ForEach-Object {
            if ($_ -is [PSCustomObject] -and $_.Name) { $_.Name } else { $_ }
        })
    }

    $current = $script:NetboxConfig.BranchStack.Peek()
    if ($Full) {
        return $current
    }
    # Return just the name for backwards compatibility
    if ($current -is [PSCustomObject] -and $current.Name) {
        return $current.Name
    }
    return $current
}
