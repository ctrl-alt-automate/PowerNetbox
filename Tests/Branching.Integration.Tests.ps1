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

Describe "Branching Plugin Integration Tests" -Tag 'BranchingIntegration' -Skip:$script:SkipTests {
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
    }

    AfterAll {
        # Clean up any branches created during tests
        foreach ($branchId in $script:CreatedBranches) {
            try {
                Remove-NBBranch -Id $branchId -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Failed to clean up branch $branchId: $_"
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
}
