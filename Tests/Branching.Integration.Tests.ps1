<#
.SYNOPSIS
    Integration tests for Netbox Branching plugin functions.

.DESCRIPTION
    Tests PowerNetbox branching functions against a live Netbox instance
    with the netbox-branching plugin installed.

    These tests require:
    - Running Netbox instance with branching plugin
    - NETBOX_HOST environment variable
    - NETBOX_TOKEN environment variable

.NOTES
    These tests create and delete branches in the target Netbox instance.
    Do NOT run against production environments.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    # Skip all tests if environment variables not set
    $script:SkipTests = $false
    if (-not $env:NETBOX_HOST -or -not $env:NETBOX_TOKEN) {
        Write-Warning "NETBOX_HOST or NETBOX_TOKEN not set - skipping branching integration tests"
        $script:SkipTests = $true
    }
}

Describe "Branching Plugin Integration Tests" -Tag 'Integration', 'Branching', 'Live' -Skip:$script:SkipTests {
    BeforeAll {
        # Connect to Netbox
        $Credential = [PSCredential]::new(
            'api',
            (ConvertTo-SecureString $env:NETBOX_TOKEN -AsPlainText -Force)
        )

        # Determine scheme based on host
        $Scheme = if ($env:NETBOX_HOST -match '^localhost|^127\.') { 'http' } else { 'https' }

        Connect-NBAPI -Hostname $env:NETBOX_HOST -Credential $Credential -Scheme $Scheme

        # Check if branching plugin is available
        $script:BranchingAvailable = Test-NBBranchingAvailable -Quiet
        if (-not $script:BranchingAvailable) {
            Write-Warning "Branching plugin not available on target Netbox"
        }

        # Track branches created for cleanup
        $script:CreatedBranches = @()
        # Track sites created for cleanup
        $script:CreatedSites = @()
    }

    AfterAll {
        # Clean up any branches created during tests
        foreach ($branchId in $script:CreatedBranches) {
            try {
                Remove-NBBranch -Id $branchId -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Failed to clean up branch ${branchId}: ${_}"
            }
        }
        # Clean up any sites created during tests
        foreach ($siteId in $script:CreatedSites) {
            try {
                Remove-NBDCIMSite -Id $siteId -Force -ErrorAction Stop
            } catch {
                Write-Warning "Failed to clean up site ${siteId}: ${_}"
            }
        }
    }

    Context "Test-NBBranchingAvailable" -Skip:(-not $script:BranchingAvailable) {
        It "Should return true when branching plugin is installed" {
            $result = Test-NBBranchingAvailable
            $result | Should -BeTrue
        }

        It "Should return true with -Quiet" {
            $result = Test-NBBranchingAvailable -Quiet
            $result | Should -BeTrue
        }
    }

    Context "Branch CRUD Operations" -Skip:(-not $script:BranchingAvailable) {
        It "Should list branches (initially empty or with existing branches)" {
            $branches = Get-NBBranch
            # Should not throw; may be empty or contain existing branches
            $branches | Should -Not -BeNullOrEmpty -Because "API should return a response"
        }

        It "Should create a new branch" {
            $branchName = "ci-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $branch = New-NBBranch -Name $branchName -Description "CI integration test branch" -Force

            $branch | Should -Not -BeNullOrEmpty
            $branch.name | Should -Be $branchName
            $branch.status.value | Should -Be 'new'
            $branch.schema_id | Should -Not -BeNullOrEmpty

            # Track for cleanup
            $script:CreatedBranches += $branch.id
            $script:TestBranch = $branch
        }

        It "Should get branch by ID" {
            if (-not $script:TestBranch) {
                Set-ItResult -Skipped -Because "No test branch created"
                return
            }

            $branch = Get-NBBranch -Id $script:TestBranch.id
            $branch | Should -Not -BeNullOrEmpty
            $branch.id | Should -Be $script:TestBranch.id
            $branch.name | Should -Be $script:TestBranch.name
        }

        It "Should get branch by name" {
            if (-not $script:TestBranch) {
                Set-ItResult -Skipped -Because "No test branch created"
                return
            }

            $branch = Get-NBBranch -Name $script:TestBranch.name
            $branch | Should -Not -BeNullOrEmpty
            $branch.name | Should -Be $script:TestBranch.name
        }

        It "Should update branch description" {
            if (-not $script:TestBranch) {
                Set-ItResult -Skipped -Because "No test branch created"
                return
            }

            $newDescription = "Updated description at $(Get-Date)"
            $updated = Set-NBBranch -Id $script:TestBranch.id -Description $newDescription -Force

            $updated | Should -Not -BeNullOrEmpty
            $updated.description | Should -Be $newDescription
        }

        It "Should delete branch" {
            if (-not $script:TestBranch) {
                Set-ItResult -Skipped -Because "No test branch created"
                return
            }

            # Remove branch
            Remove-NBBranch -Id $script:TestBranch.id -Force

            # Verify deleted
            $deleted = Get-NBBranch -Id $script:TestBranch.id -ErrorAction SilentlyContinue
            $deleted | Should -BeNullOrEmpty

            # Remove from cleanup list since already deleted
            $script:CreatedBranches = $script:CreatedBranches | Where-Object { $_ -ne $script:TestBranch.id }
        }
    }

    Context "Branch Context Management" -Skip:(-not $script:BranchingAvailable) {
        BeforeAll {
            # Create a branch for context tests
            $branchName = "ci-context-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $script:ContextBranch = New-NBBranch -Name $branchName -Description "Context test branch" -Force
            $script:CreatedBranches += $script:ContextBranch.id
        }

        AfterEach {
            # Ensure we exit any branch context after each test
            while (Get-NBBranchContext) {
                Exit-NBBranch | Out-Null
            }
        }

        It "Should enter a branch context" {
            Enter-NBBranch -Name $script:ContextBranch.name

            $context = Get-NBBranchContext
            $context | Should -Be $script:ContextBranch.name
        }

        It "Should exit a branch context" {
            Enter-NBBranch -Name $script:ContextBranch.name
            $exited = Exit-NBBranch

            $exited | Should -Be $script:ContextBranch.name
            Get-NBBranchContext | Should -BeNullOrEmpty
        }

        It "Should get full context with -Full" {
            Enter-NBBranch -Name $script:ContextBranch.name

            $context = Get-NBBranchContext -Full
            $context.Name | Should -Be $script:ContextBranch.name
            $context.SchemaId | Should -Be $script:ContextBranch.schema_id
            $context.Id | Should -Be $script:ContextBranch.id
        }

        It "Should execute scriptblock in branch context with Invoke-NBInBranch" {
            $result = Invoke-NBInBranch -Branch $script:ContextBranch.name -ScriptBlock {
                Get-NBBranchContext
            }

            # The result should include the branch name from within the context
            $result | Should -Contain $script:ContextBranch.name

            # Should be outside context after execution
            Get-NBBranchContext | Should -BeNullOrEmpty
        }
    }

    Context "Branch Sync Operations" -Skip:(-not $script:BranchingAvailable) -Tag 'Branching', 'Sync' {
        BeforeAll {
            # Create a branch for sync tests
            $branchName = "ci-sync-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $script:SyncBranch = New-NBBranch -Name $branchName -Description "Sync test branch" -Force
            $script:CreatedBranches += $script:SyncBranch.id
        }

        It "Should sync a branch with main using ID" {
            if (-not $script:SyncBranch) {
                Set-ItResult -Skipped -Because "No sync branch created"
                return
            }

            # Sync should succeed (even if no changes in main)
            # The sync operation should not throw
            { Sync-NBBranch -Id $script:SyncBranch.id -Confirm:$false } | Should -Not -Throw
        }

        It "Should sync a branch via pipeline" {
            if (-not $script:SyncBranch) {
                Set-ItResult -Skipped -Because "No sync branch created"
                return
            }

            # Pipeline sync should work
            { $script:SyncBranch | Sync-NBBranch -Confirm:$false } | Should -Not -Throw
        }

        It "Should support -WhatIf on Sync-NBBranch" {
            if (-not $script:SyncBranch) {
                Set-ItResult -Skipped -Because "No sync branch created"
                return
            }

            # WhatIf should not actually sync
            { Sync-NBBranch -Id $script:SyncBranch.id -WhatIf } | Should -Not -Throw
        }
    }

    Context "Branch Merge and Revert Operations" -Skip:(-not $script:BranchingAvailable) -Tag 'Branching', 'Merge' {
        BeforeAll {
            # Create a branch for merge tests
            $branchName = "ci-merge-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $script:MergeBranch = New-NBBranch -Name $branchName -Description "Merge test branch" -Force
            $script:CreatedBranches += $script:MergeBranch.id

            # Create a test site within the branch context to have something to merge
            Enter-NBBranch -Name $script:MergeBranch.name
            $siteName = "ci-branch-site-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $script:BranchSite = New-NBDCIMSite -Name $siteName -Slug ($siteName -replace '[^a-z0-9-]', '-').ToLower() -Force
            Exit-NBBranch | Out-Null
        }

        AfterAll {
            # Ensure we exit any branch context
            while (Get-NBBranchContext) {
                Exit-NBBranch | Out-Null
            }
        }

        It "Should merge a branch into main" {
            if (-not $script:MergeBranch) {
                Set-ItResult -Skipped -Because "No merge branch created"
                return
            }

            # Merge the branch
            $result = Merge-NBBranch -Id $script:MergeBranch.id -Confirm:$false

            # After merge, branch status should be 'merged'
            $mergedBranch = Get-NBBranch -Id $script:MergeBranch.id
            $mergedBranch.status.value | Should -Be 'merged'
        }

        It "Should verify merged changes appear in main" {
            if (-not $script:BranchSite) {
                Set-ItResult -Skipped -Because "No branch site created"
                return
            }

            # After merge, the site should be visible in main context
            $mainSite = Get-NBDCIMSite -Name $script:BranchSite.name -ErrorAction SilentlyContinue
            $mainSite | Should -Not -BeNullOrEmpty -Because "Site created in branch should exist in main after merge"
            $mainSite.name | Should -Be $script:BranchSite.name

            # Track for cleanup (site now exists in main)
            $script:CreatedSites += $mainSite.id
        }

        It "Should revert a merged branch with Undo-NBBranchMerge" {
            if (-not $script:MergeBranch) {
                Set-ItResult -Skipped -Because "No merge branch created"
                return
            }

            # Verify branch is merged before revert
            $preMergeBranch = Get-NBBranch -Id $script:MergeBranch.id
            $preMergeBranch.status.value | Should -Be 'merged' -Because "Branch should be merged before revert"

            # Revert the merge
            $result = Undo-NBBranchMerge -Id $script:MergeBranch.id -Confirm:$false

            # After revert, the changes should be undone
            # The branch status may change back to 'ready' or 'reverted' depending on API
            $revertedBranch = Get-NBBranch -Id $script:MergeBranch.id
            $revertedBranch | Should -Not -BeNullOrEmpty

            # The site should no longer exist in main after revert
            $mainSite = Get-NBDCIMSite -Name $script:BranchSite.name -ErrorAction SilentlyContinue
            $mainSite | Should -BeNullOrEmpty -Because "Site should be removed from main after merge revert"

            # Remove from cleanup list since site was reverted
            $script:CreatedSites = $script:CreatedSites | Where-Object { $_ -ne $script:BranchSite.id }
        }

        It "Should support -WhatIf on Merge-NBBranch" {
            # Create a fresh branch for WhatIf test
            $whatIfBranchName = "ci-whatif-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $whatIfBranch = New-NBBranch -Name $whatIfBranchName -Description "WhatIf test branch" -Force
            $script:CreatedBranches += $whatIfBranch.id

            # WhatIf should not actually merge
            { Merge-NBBranch -Id $whatIfBranch.id -WhatIf } | Should -Not -Throw

            # Branch should still be in 'new' or 'ready' status
            $branch = Get-NBBranch -Id $whatIfBranch.id
            $branch.status.value | Should -Not -Be 'merged'
        }

        It "Should support -WhatIf on Undo-NBBranchMerge" {
            # Create a fresh branch and merge it for this test (self-contained)
            $branchName = "ci-whatif-undo-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $branch = New-NBBranch -Name $branchName -Description "WhatIf undo test" -Force
            $script:CreatedBranches += $branch.id
            Merge-NBBranch -Id $branch.id -Confirm:$false

            $mergedBranch = Get-NBBranch -Id $branch.id
            if ($mergedBranch.status.value -ne 'merged') {
                Set-ItResult -Skipped -Because "Branch for WhatIf undo test did not merge correctly."
                return
            }

            # WhatIf should not actually revert
            { Undo-NBBranchMerge -Id $branch.id -WhatIf } | Should -Not -Throw

            # Verify the branch is still merged
            $branchAfter = Get-NBBranch -Id $branch.id
            $branchAfter.status.value | Should -Be 'merged'
        }
    }

    Context "Object Creation Within Branch Context" -Skip:(-not $script:BranchingAvailable) -Tag 'Branching', 'Context' {
        BeforeAll {
            # Create a branch for object creation tests
            $branchName = "ci-objects-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $script:ObjectsBranch = New-NBBranch -Name $branchName -Description "Object creation test branch" -Force
            $script:CreatedBranches += $script:ObjectsBranch.id
        }

        AfterAll {
            # Ensure we exit any branch context
            while (Get-NBBranchContext) {
                Exit-NBBranch | Out-Null
            }
        }

        It "Should create a site within branch context" {
            if (-not $script:ObjectsBranch) {
                Set-ItResult -Skipped -Because "No objects branch created"
                return
            }

            Enter-NBBranch -Name $script:ObjectsBranch.name

            $siteName = "ci-in-branch-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $site = New-NBDCIMSite -Name $siteName -Slug ($siteName -replace '[^a-z0-9-]', '-').ToLower() -Force

            $site | Should -Not -BeNullOrEmpty
            $site.name | Should -Be $siteName
            $script:InBranchSite = $site

            Exit-NBBranch | Out-Null
        }

        It "Should not see branch-created site in main context" {
            if (-not $script:InBranchSite) {
                Set-ItResult -Skipped -Because "No in-branch site created"
                return
            }

            # Outside branch context, the site should not be visible
            $mainSite = Get-NBDCIMSite -Name $script:InBranchSite.name -ErrorAction SilentlyContinue
            $mainSite | Should -BeNullOrEmpty -Because "Site created in branch should not be visible in main until merged"
        }

        It "Should see branch-created site when re-entering branch context" {
            if (-not $script:InBranchSite -or -not $script:ObjectsBranch) {
                Set-ItResult -Skipped -Because "No in-branch site or branch created"
                return
            }

            Enter-NBBranch -Name $script:ObjectsBranch.name

            $branchSite = Get-NBDCIMSite -Name $script:InBranchSite.name -ErrorAction SilentlyContinue
            $branchSite | Should -Not -BeNullOrEmpty -Because "Site should be visible within branch context"
            $branchSite.name | Should -Be $script:InBranchSite.name

            Exit-NBBranch | Out-Null
        }

        It "Should create objects using Invoke-NBInBranch" {
            if (-not $script:ObjectsBranch) {
                Set-ItResult -Skipped -Because "No objects branch created"
                return
            }

            $siteName = "ci-invoke-site-$(Get-Date -Format 'yyyyMMddHHmmss')"

            $site = Invoke-NBInBranch -Branch $script:ObjectsBranch.name -ScriptBlock {
                param($SiteName)
                New-NBDCIMSite -Name $SiteName -Slug ($SiteName -replace '[^a-z0-9-]', '-').ToLower() -Force
            } -ArgumentList $siteName

            $site | Should -Not -BeNullOrEmpty
            $site.name | Should -Be $siteName

            # Verify we're back in main context
            Get-NBBranchContext | Should -BeNullOrEmpty
        }
    }

    Context "Branch Events" -Skip:(-not $script:BranchingAvailable) {
        It "Should list branch events" {
            $events = Get-NBBranchEvent
            # Should return empty or events list
            { $events } | Should -Not -Throw
        }
    }

    Context "Change Diffs" -Skip:(-not $script:BranchingAvailable) {
        It "Should list change diffs" {
            $diffs = Get-NBChangeDiff
            # Should return empty or diffs list
            { $diffs } | Should -Not -Throw
        }
    }

    Context "Negative Tests - Invalid Operations" -Skip:(-not $script:BranchingAvailable) -Tag 'Branching', 'Negative' {
        It "Should fail to get a non-existent branch by ID" {
            # Use a very high ID that is unlikely to exist
            $nonExistentId = 999999999

            $result = Get-NBBranch -Id $nonExistentId -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It "Should fail to get a non-existent branch by name" {
            $nonExistentName = "this-branch-does-not-exist-$(Get-Random)"

            $result = Get-NBBranch -Name $nonExistentName -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It "Should fail to enter a non-existent branch context" {
            $nonExistentName = "this-branch-does-not-exist-$(Get-Random)"

            { Enter-NBBranch -Name $nonExistentName } | Should -Throw -Because "Cannot enter a branch that does not exist"
        }

        It "Should fail to enter a branch by non-existent ID" {
            $nonExistentId = 999999999

            { Enter-NBBranch -Id $nonExistentId } | Should -Throw -Because "Cannot enter a branch that does not exist"
        }

        It "Should fail to sync a non-existent branch" {
            $nonExistentId = 999999999

            { Sync-NBBranch -Id $nonExistentId -Confirm:$false -ErrorAction Stop } | Should -Throw
        }

        It "Should fail to merge a non-existent branch" {
            $nonExistentId = 999999999

            { Merge-NBBranch -Id $nonExistentId -Confirm:$false -ErrorAction Stop } | Should -Throw
        }

        It "Should fail to revert a non-existent branch" {
            $nonExistentId = 999999999

            { Undo-NBBranchMerge -Id $nonExistentId -Confirm:$false -ErrorAction Stop } | Should -Throw
        }

        It "Should fail to delete a non-existent branch" {
            $nonExistentId = 999999999

            { Remove-NBBranch -Id $nonExistentId -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should fail to create a branch with empty name" {
            { New-NBBranch -Name "" -Force } | Should -Throw -Because "Branch name cannot be empty"
        }

        It "Should fail to create a branch with null name" {
            { New-NBBranch -Name $null -Force } | Should -Throw -Because "Branch name cannot be null"
        }

        It "Should fail to update a non-existent branch" {
            $nonExistentId = 999999999

            { Set-NBBranch -Id $nonExistentId -Description "Test" -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should return nothing when exiting without entering a branch" {
            # Ensure we're not in any branch context
            while (Get-NBBranchContext) {
                Exit-NBBranch | Out-Null
            }

            # Exit should return nothing when not in a branch
            $result = Exit-NBBranch
            $result | Should -BeNullOrEmpty
        }

        It "Should fail to merge an already merged branch again" {
            # Create and merge a branch
            $branchName = "ci-double-merge-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $branch = New-NBBranch -Name $branchName -Description "Double merge test" -Force
            $script:CreatedBranches += $branch.id

            # Merge the branch
            Merge-NBBranch -Id $branch.id -Confirm:$false -ErrorAction SilentlyContinue

            # Verify branch is merged
            $mergedBranch = Get-NBBranch -Id $branch.id
            if ($mergedBranch.status.value -ne 'merged') {
                Set-ItResult -Skipped -Because "Branch did not merge properly"
                return
            }

            # Attempting to merge again should fail (branch is already merged)
            { Merge-NBBranch -Id $branch.id -Confirm:$false -ErrorAction Stop } | Should -Throw
        }
    }

    Context "Pipeline Support" -Skip:(-not $script:BranchingAvailable) -Tag 'Branching', 'Pipeline' {
        BeforeAll {
            # Create a branch for pipeline tests
            $branchName = "ci-pipeline-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $script:PipelineBranch = New-NBBranch -Name $branchName -Description "Pipeline test branch" -Force
            $script:CreatedBranches += $script:PipelineBranch.id
        }

        It "Should support Get-NBBranch piped to Set-NBBranch" {
            if (-not $script:PipelineBranch) {
                Set-ItResult -Skipped -Because "No pipeline branch created"
                return
            }

            $newDescription = "Pipeline updated at $(Get-Date)"
            $result = Get-NBBranch -Id $script:PipelineBranch.id | Set-NBBranch -Description $newDescription -Force

            $result | Should -Not -BeNullOrEmpty
            $result.description | Should -Be $newDescription
        }

        It "Should support Get-NBBranch piped to Sync-NBBranch" {
            if (-not $script:PipelineBranch) {
                Set-ItResult -Skipped -Because "No pipeline branch created"
                return
            }

            { Get-NBBranch -Id $script:PipelineBranch.id | Sync-NBBranch -Confirm:$false } | Should -Not -Throw
        }

        It "Should support Get-NBBranch piped to Enter-NBBranch" {
            if (-not $script:PipelineBranch) {
                Set-ItResult -Skipped -Because "No pipeline branch created"
                return
            }

            Get-NBBranch -Id $script:PipelineBranch.id | Enter-NBBranch

            $context = Get-NBBranchContext
            $context | Should -Be $script:PipelineBranch.name

            Exit-NBBranch | Out-Null
        }

        It "Should support Get-NBBranch piped to Remove-NBBranch" {
            # Create a branch specifically for deletion
            $deleteBranchName = "ci-pipe-delete-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $deleteBranch = New-NBBranch -Name $deleteBranchName -Description "Pipeline delete test" -Force
            $script:CreatedBranches += $deleteBranch.id

            # Delete via pipeline
            Get-NBBranch -Id $deleteBranch.id | Remove-NBBranch -Force

            # Verify deleted
            $result = Get-NBBranch -Id $deleteBranch.id -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }
}
