# Branching Support

PowerNetbox provides full support for the [netbox-branching](https://github.com/netboxlabs/netbox-branching) plugin, enabling you to stage changes in isolated branches before merging them to the main database.

## Prerequisites

- Netbox 4.1 or later
- [netbox-branching](https://github.com/netboxlabs/netbox-branching) plugin installed on your Netbox server

## Checking Availability

Before using branching features, check if the plugin is available:

```powershell
# Check if branching is available
if (Test-NBBranchingAvailable) {
    Write-Host "Branching is available!"
} else {
    Write-Host "Branching plugin not installed"
}
```

## Basic Workflow

### Creating a Branch

```powershell
# Create a new branch
$branch = New-NBBranch -Name "feature/new-datacenter" -Description "Planning new datacenter"

# List all branches
Get-NBBranch

# Get branches by status
Get-NBBranch -Status ready
Get-NBBranch -Status merged
```

### Working in a Branch Context

PowerNetbox supports three ways to work within a branch:

#### Method 1: Enter/Exit Pattern

This pattern is similar to `Push-Location`/`Pop-Location`:

```powershell
# Enter the branch context
Enter-NBBranch -Name "feature/new-datacenter"

# All operations now work within the branch
New-NBDCIMSite -Name "DC-Amsterdam" -Slug "dc-ams"
New-NBDCIMDevice -Name "server-01" -DeviceType 1 -Site 1
New-NBIPAMAddress -Address "10.0.0.1/24"

# Exit back to main
Exit-NBBranch
```

#### Method 2: Invoke-NBInBranch (Recommended)

This is the safest method as it automatically restores context even if errors occur:

```powershell
# Execute operations in a branch
Invoke-NBInBranch -Branch "feature/new-datacenter" -ScriptBlock {
    New-NBDCIMSite -Name "DC-Amsterdam" -Slug "dc-ams"
    New-NBDCIMDevice -Name "server-01" -DeviceType 1 -Site 1
}
# Context is automatically restored after the scriptblock
```

#### Method 3: Nested Contexts

You can nest branch contexts:

```powershell
Enter-NBBranch -Name "outer-branch"
    # Operations in outer-branch
    Enter-NBBranch -Name "inner-branch"
        # Operations in inner-branch
    Exit-NBBranch  # Back to outer-branch
Exit-NBBranch  # Back to main

# Check current context
Get-NBBranchContext  # Returns current branch name or $null

# View the entire stack
Get-NBBranchContext -Stack
```

## Reviewing Changes

See what changes exist in a branch:

```powershell
# Get all changes in a branch
Get-NBChangeDiff -Branch_Id 1

# Filter by action type
Get-NBChangeDiff -Branch_Id 1 -Action create
Get-NBChangeDiff -Branch_Id 1 -Action update
Get-NBChangeDiff -Branch_Id 1 -Action delete

# Filter by object type
Get-NBChangeDiff -Branch_Id 1 -Object_Type 'dcim.device'

# Check for conflicts
$conflicts = Get-NBChangeDiff -Branch_Id 1 | Where-Object { $_.conflicts }
if ($conflicts) {
    Write-Warning "Branch has $($conflicts.Count) conflict(s)"
}
```

## Syncing and Merging

### Sync with Main

Keep your branch up-to-date with changes in main:

```powershell
# Sync a branch
Sync-NBBranch -Id 1

# Or using pipeline
Get-NBBranch -Name "feature/new-datacenter" | Sync-NBBranch
```

### Merge to Main

Merge your changes back to the main database:

```powershell
# Merge (will fail if conflicts exist)
Merge-NBBranch -Id 1

# Force merge despite conflicts
Merge-NBBranch -Id 1 -Force

# Using pipeline
Get-NBBranch -Name "feature/new-datacenter" | Merge-NBBranch
```

### Reverting a Merge

If you need to undo a merge:

```powershell
# Revert a merged branch
Undo-NBBranchMerge -Id 1

# Using pipeline
Get-NBBranch -Status merged | Where-Object { $_.name -eq "feature/new-datacenter" } | Undo-NBBranchMerge
```

## Branch Events

Track operations performed on branches:

```powershell
# Get all branch events
Get-NBBranchEvent

# Get events for a specific branch
Get-NBBranchEvent -Branch_Id 1
```

## Complete Example: Datacenter Planning

Here's a complete workflow for planning a new datacenter:

```powershell
# Check if branching is available
if (-not (Test-NBBranchingAvailable)) {
    throw "Branching plugin not available"
}

# Create planning branch
$branch = New-NBBranch -Name "planning/dc-amsterdam" -Description "Q1 2025 Datacenter Planning"

# Work in the branch
Invoke-NBInBranch -Branch "planning/dc-amsterdam" -ScriptBlock {
    # Create site
    $site = New-NBDCIMSite -Name "Amsterdam DC" -Slug "dc-ams" -Status "planned"

    # Create racks
    1..10 | ForEach-Object {
        New-NBDCIMRack -Name "AMS-R$($_)" -Site $site.id -U_Height 42
    }

    # Reserve IP prefixes
    New-NBIPAMPrefix -Prefix "10.100.0.0/16" -Description "Amsterdam DC supernet"
}

# Review what was created
$changes = Get-NBChangeDiff -Branch_Id $branch.id
Write-Host "Created $($changes.Count) objects in branch"

# When ready, sync and merge
$branch | Sync-NBBranch
$branch | Merge-NBBranch
```

## Function Reference

| Function | Description |
|----------|-------------|
| `Test-NBBranchingAvailable` | Check if branching plugin is available |
| `Enter-NBBranch` | Enter a branch context |
| `Exit-NBBranch` | Exit the current branch context |
| `Get-NBBranchContext` | Get the current branch context |
| `Invoke-NBInBranch` | Execute a scriptblock in a branch |
| `Get-NBBranch` | Retrieve branch(es) |
| `New-NBBranch` | Create a new branch |
| `Set-NBBranch` | Update a branch |
| `Remove-NBBranch` | Delete a branch |
| `Sync-NBBranch` | Sync branch with main |
| `Merge-NBBranch` | Merge branch to main |
| `Undo-NBBranchMerge` | Revert a merged branch |
| `Get-NBBranchEvent` | Get branch event history |
| `Get-NBChangeDiff` | Get changes in a branch |

## See Also

- [netbox-branching GitHub](https://github.com/netboxlabs/netbox-branching)
- [NetBox Branching Public Beta Announcement](https://netboxlabs.com/blog/netbox-branching-public-beta/)
