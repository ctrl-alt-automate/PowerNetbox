<#
.SYNOPSIS
    Enters a branch context for subsequent Netbox API operations.

.DESCRIPTION
    Sets the active branch context so that all subsequent Netbox API calls
    will operate within the specified branch. This works like Push-Location
    and can be nested. Use Exit-NBBranch to leave the branch context.

    The branching plugin must be installed on the Netbox server.

.PARAMETER Name
    The name of the branch to enter.

.PARAMETER Id
    The ID of the branch to enter.

.PARAMETER PassThru
    Return the branch object after entering.

.OUTPUTS
    [PSCustomObject] If -PassThru is specified, returns the branch object.

.EXAMPLE
    Enter-NBBranch -Name "feature/new-datacenter"
    Enter the branch named "feature/new-datacenter".

.EXAMPLE
    Enter-NBBranch -Name "outer"
    Enter-NBBranch -Name "inner"
    # Now in "inner" context
    Exit-NBBranch  # Back to "outer"
    Exit-NBBranch  # Back to main
    Demonstrates nested branch contexts.

.EXAMPLE
    $branch = Enter-NBBranch -Name "feature" -PassThru
    Enter branch and capture the branch object.

.LINK
    Exit-NBBranch
    Get-NBBranchContext
    Invoke-NBInBranch
#>
function Enter-NBBranch {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ByName', Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'ById', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$PassThru
    )

    process {
        CheckNetboxIsConnected

        # Verify branching is available
        if (-not (Test-NBBranchingAvailable -Quiet)) {
            throw "Netbox Branching plugin is not installed on the target server."
        }

        # Verify the branch exists
        $branch = switch ($PSCmdlet.ParameterSetName) {
            'ByName' {
                $found = Get-NBBranch -Name $Name -ErrorAction SilentlyContinue
                if (-not $found) {
                    throw "Branch '$Name' not found. Use Get-NBBranch to list available branches."
                }
                $found
            }
            'ById' {
                $found = Get-NBBranch -Id $Id -ErrorAction SilentlyContinue
                if (-not $found) {
                    throw "Branch with ID $Id not found."
                }
                $found
            }
        }

        # Validate branch has schema_id (required for API header)
        if (-not $branch.schema_id) {
            throw "Branch object missing 'schema_id' property. This may indicate an incompatible branching plugin version."
        }

        # Create branch context object with both name and schema_id
        $branchContext = [PSCustomObject]@{
            Name     = if ($branch.name) { $branch.name } else { $Name }
            SchemaId = $branch.schema_id
            Id       = $branch.id
        }

        # Initialize stack if needed, or reinitialize if wrong type (upgrade from string stack)
        if (-not $script:NetboxConfig.BranchStack -or
            $script:NetboxConfig.BranchStack.GetType().GenericTypeArguments[0] -ne [PSCustomObject]) {
            $script:NetboxConfig.BranchStack = [System.Collections.Generic.Stack[object]]::new()
        }

        # Push onto stack
        $script:NetboxConfig.BranchStack.Push($branchContext)
        Write-Verbose "Entered branch '$($branchContext.Name)' (schema_id: $($branchContext.SchemaId), stack depth: $($script:NetboxConfig.BranchStack.Count))"

        if ($PassThru) {
            $branch
        }
    }
}
