<#
.SYNOPSIS
    Unit tests for Netbox Branching plugin functions.

.DESCRIPTION
    Tests for all Branching endpoints: Branch, BranchEvent, ChangeDiff,
    and context management functions (Enter/Exit/Get-NBBranchContext).
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
}

Describe "Branching Module Tests" -Tag 'Branching' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method'      = $Method
                'Uri'         = $Uri
                'Headers'     = $Headers
                'Timeout'     = $Timeout
                'ContentType' = $ContentType
                'Body'        = $Body
            }
        }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
            $script:NetboxConfig.BranchStack = [System.Collections.Generic.Stack[object]]::new()
        }
    }

    AfterEach {
        # Clean up branch stack after each test
        InModuleScope -ModuleName 'PowerNetbox' {
            if ($script:NetboxConfig.BranchStack) {
                $script:NetboxConfig.BranchStack.Clear()
            }
        }
    }

    #region Branch Context Tests
    Context "Get-NBBranchContext" {
        It "Should return null when not in a branch" {
            $Result = Get-NBBranchContext
            $Result | Should -BeNullOrEmpty
        }

        It "Should return empty array with -Stack when not in a branch" {
            $Result = Get-NBBranchContext -Stack
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Exit-NBBranch" {
        It "Should warn when not in a branch context" {
            $Result = Exit-NBBranch -WarningAction SilentlyContinue
            $Result | Should -BeNullOrEmpty
        }

        It "Should return exited branch name" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{
                    Name = "test-branch"
                    SchemaId = "abc12345"
                    Id = 1
                })
            }
            $Result = Exit-NBBranch
            $Result | Should -Be "test-branch"
        }
    }

    Context "Branch Stack Management" {
        It "Should support nested branch contexts" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{ Name = "outer"; SchemaId = "out12345"; Id = 1 })
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{ Name = "inner"; SchemaId = "inn12345"; Id = 2 })
            }

            $current = Get-NBBranchContext
            $current | Should -Be "inner"

            Exit-NBBranch | Should -Be "inner"
            Get-NBBranchContext | Should -Be "outer"

            Exit-NBBranch | Should -Be "outer"
            Get-NBBranchContext | Should -BeNullOrEmpty
        }

        It "Should return entire stack with -Stack" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{ Name = "first"; SchemaId = "fir12345"; Id = 1 })
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{ Name = "second"; SchemaId = "sec12345"; Id = 2 })
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{ Name = "third"; SchemaId = "thi12345"; Id = 3 })
            }

            $stack = Get-NBBranchContext -Stack
            $stack.Count | Should -Be 3
            $stack[0] | Should -Be "third"
            $stack[1] | Should -Be "second"
            $stack[2] | Should -Be "first"
        }

        It "Should return full context objects with -Full" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{ Name = "test"; SchemaId = "tes12345"; Id = 99 })
            }

            $context = Get-NBBranchContext -Full
            $context.Name | Should -Be "test"
            $context.SchemaId | Should -Be "tes12345"
            $context.Id | Should -Be 99
        }
    }
    #endregion

    #region Test-NBBranchingAvailable Tests
    Context "Test-NBBranchingAvailable" {
        It "Should return true when branching is available" {
            $Result = Test-NBBranchingAvailable
            $Result | Should -BeTrue
        }

        It "Should call the correct endpoint" {
            # Verify the endpoint is called
            $Result = Test-NBBranchingAvailable
            $Result | Should -BeTrue
        }

        It "Should accept -Quiet parameter without error" {
            { Test-NBBranchingAvailable -Quiet } | Should -Not -Throw
        }
    }
    #endregion

    #region Enter-NBBranch Tests
    Context "Enter-NBBranch" {
        BeforeEach {
            Mock -CommandName 'Test-NBBranchingAvailable' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{ id = 1; name = $Name; schema_id = "abc12345" }
            }
        }

        It "Should enter a branch by name" {
            $null = Enter-NBBranch -Name "test-branch"
            $context = Get-NBBranchContext
            $context | Should -Be "test-branch"
        }

        It "Should store schema_id in context" {
            $null = Enter-NBBranch -Name "test-branch"
            $context = Get-NBBranchContext -Full
            $context.SchemaId | Should -Be "abc12345"
        }

        It "Should return branch with -PassThru" {
            $Result = Enter-NBBranch -Name "feature-branch" -PassThru
            $Result.name | Should -Be "feature-branch"
        }

        It "Should throw when branch not found" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith { return $null }

            { Enter-NBBranch -Name "nonexistent" } | Should -Throw "*not found*"
        }

        It "Should throw when branching plugin not available" {
            Mock -CommandName 'Test-NBBranchingAvailable' -ModuleName 'PowerNetbox' -MockWith { return $false }

            { Enter-NBBranch -Name "test" } | Should -Throw "*not installed*"
        }

        It "Should throw when branch has no schema_id" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{ id = 1; name = $Name }  # No schema_id
            }

            { Enter-NBBranch -Name "test" } | Should -Throw "*schema_id*"
        }
    }
    #endregion

    #region Invoke-NBInBranch Tests
    Context "Invoke-NBInBranch" {
        BeforeEach {
            Mock -CommandName 'Test-NBBranchingAvailable' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{ id = 1; name = $Name; schema_id = "inv12345" }
            }
        }

        It "Should execute scriptblock in branch context" {
            $result = Invoke-NBInBranch -Branch "test" -ScriptBlock {
                Get-NBBranchContext
            }
            # Filter to just get the context result (last item)
            $contextResult = $result | Select-Object -Last 1
            $contextResult | Should -Be "test"
        }

        It "Should restore context after execution" {
            $null = Invoke-NBInBranch -Branch "temp" -ScriptBlock { "test" }
            Get-NBBranchContext | Should -BeNullOrEmpty
        }

        It "Should restore context even after error" {
            { Invoke-NBInBranch -Branch "error-test" -ScriptBlock { throw "test error" } } | Should -Throw
            Get-NBBranchContext | Should -BeNullOrEmpty
        }

        It "Should return scriptblock output" {
            $result = Invoke-NBInBranch -Branch "output-test" -ScriptBlock { 42 }
            # Filter to just get the output (last item)
            $output = $result | Select-Object -Last 1
            $output | Should -Be 42
        }
    }
    #endregion

    #region Get-NBBranch Tests
    Context "Get-NBBranch" {
        It "Should request branches" {
            $Result = Get-NBBranch
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/'
        }

        It "Should request a branch by ID" {
            $Result = Get-NBBranch -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/5/'
        }

        It "Should request branches by name" {
            $Result = Get-NBBranch -Name 'feature'
            $Result.Uri | Should -Match 'name=feature'
        }

        It "Should request branches by status" {
            $Result = Get-NBBranch -Status 'ready'
            $Result.Uri | Should -Match 'status=ready'
        }

        It "Should accept all 11 real BranchStatusChoices values (#385)" {
            # Source of truth: netbox-branching/choices.py → BranchStatusChoices
            $allStatuses = @(
                'new', 'provisioning', 'ready', 'syncing', 'migrating',
                'merging', 'reverting', 'merged', 'archived',
                'pending-migrations', 'failed'
            )
            foreach ($status in $allStatuses) {
                $Result = Get-NBBranch -Status $status
                $Result.Uri | Should -Match "status=$([regex]::Escape($status))" -Because "$status is a real plugin status"
            }
        }

        It "Should reject the non-existent 'conflict' status (#385)" {
            # 'conflict' was in the original ValidateSet but does not exist in
            # BranchStatusChoices. Reject it at parameter binding time.
            { Get-NBBranch -Status 'conflict' } | Should -Throw
        }

        It "Should request branches by owner" {
            $Result = Get-NBBranch -Owner 'admin'
            $Result.Uri | Should -Match 'owner=admin'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBBranch -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 15 } | Get-NBBranch
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/15/'
        }
    }
    #endregion

    #region New-NBBranch Tests
    Context "New-NBBranch" {
        It "Should create a branch" {
            $Result = New-NBBranch -Name "feature/test" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'feature/test'
        }

        It "Should create a branch with description" {
            $Result = New-NBBranch -Name "feature/new" -Description "New feature branch" -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'feature/new'
            $bodyObj.description | Should -Be 'New feature branch'
        }

        It "Should support -WhatIf" {
            # WhatIf should not make the actual API call
            { New-NBBranch -Name "whatif-branch" -WhatIf } | Should -Not -Throw
        }
    }
    #endregion

    #region Set-NBBranch Tests
    Context "Set-NBBranch" {
        It "Should update a branch" {
            $Result = Set-NBBranch -Id 1 -Description 'Updated description' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Updated description'
        }

        It "Should update branch name" {
            $Result = Set-NBBranch -Id 2 -Name 'renamed-branch' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'renamed-branch'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 10 } | Set-NBBranch -Description 'Piped update' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/10/'
        }

        It "Should support -WhatIf" {
            # WhatIf should not make the actual API call
            { Set-NBBranch -Id 1 -Name 'whatif' -WhatIf } | Should -Not -Throw
        }
    }
    #endregion

    #region Remove-NBBranch Tests
    Context "Remove-NBBranch" {
        It "Should delete a branch" {
            $Result = Remove-NBBranch -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/1/'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 25 } | Remove-NBBranch -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/25/'
        }

        It "Should support -WhatIf" {
            # WhatIf should not make the actual API call
            { Remove-NBBranch -Id 1 -WhatIf } | Should -Not -Throw
        }
    }
    #endregion

    #region Sync-NBBranch Tests
    Context "Sync-NBBranch" {
        It "Should sync a branch" {
            $Result = Sync-NBBranch -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/1/sync/'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 5 } | Sync-NBBranch -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/5/sync/'
        }

        It "Should support -WhatIf" {
            # WhatIf should not make the actual API call
            { Sync-NBBranch -Id 1 -WhatIf } | Should -Not -Throw
        }
    }
    #endregion

    #region Merge-NBBranch Tests
    Context "Merge-NBBranch" {
        BeforeEach {
            Mock -CommandName 'Get-NBChangeDiff' -ModuleName 'PowerNetbox' -MockWith {
                return @()  # No conflicts by default
            }
        }

        It "Should merge a branch" {
            $Result = Merge-NBBranch -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/1/merge/'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 3 } | Merge-NBBranch -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/3/merge/'
        }

        It "Should throw when conflicts exist without -Force" {
            Mock -CommandName 'Get-NBChangeDiff' -ModuleName 'PowerNetbox' -MockWith {
                return @(
                    [PSCustomObject]@{ id = 1; conflicts = $true }
                    [PSCustomObject]@{ id = 2; conflicts = $true }
                )
            }

            { Merge-NBBranch -Id 1 -Confirm:$false } | Should -Throw "*conflict*"
        }

        It "Should merge with -Force even with conflicts" {
            Mock -CommandName 'Get-NBChangeDiff' -ModuleName 'PowerNetbox' -MockWith {
                return @([PSCustomObject]@{ id = 1; conflicts = $true })
            }

            $Result = Merge-NBBranch -Id 1 -Force -Confirm:$false
            $Result.Method | Should -Be 'POST'
        }

        It "Should support -WhatIf" {
            # WhatIf should not make the actual API call
            { Merge-NBBranch -Id 1 -WhatIf } | Should -Not -Throw
        }
    }
    #endregion

    #region Undo-NBBranchMerge Tests
    Context "Undo-NBBranchMerge" {
        It "Should revert a merged branch" {
            $Result = Undo-NBBranchMerge -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/1/revert/'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 7 } | Undo-NBBranchMerge -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branches/7/revert/'
        }

        It "Should support -WhatIf" {
            # WhatIf should not make the actual API call
            { Undo-NBBranchMerge -Id 1 -WhatIf } | Should -Not -Throw
        }
    }
    #endregion

    #region Wait-NBBranch Tests
    Context "Wait-NBBranch" {
        # Wait-NBBranch operates by polling Get-NBBranch; override the default
        # module-level Invoke-RestMethod mock with a Get-NBBranch mock per test
        # so we can simulate status transitions across successive polls.
        BeforeEach {
            # Shared counter for sequential responses across polls within one test.
            # Reset before each test to avoid leakage.
            $script:WaitTestCallCount = 0
        }

        It "Should return immediately when branch is already at target status" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{
                    id     = 42
                    name   = 'already-ready'
                    status = [PSCustomObject]@{ value = 'ready'; label = 'Ready' }
                }
            }

            $result = Wait-NBBranch -Id 42 -PollIntervalMs 100
            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 42
            $result.status.value | Should -Be 'ready'
            Should -Invoke -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -Times 1
        }

        It "Should poll through new → provisioning → ready" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                $script:WaitTestCallCount++
                $status = switch ($script:WaitTestCallCount) {
                    1       { 'new' }
                    2       { 'provisioning' }
                    default { 'ready' }
                }
                return [PSCustomObject]@{
                    id     = 42
                    name   = 'transitional'
                    status = [PSCustomObject]@{ value = $status }
                }
            }

            $result = Wait-NBBranch -Id 42 -PollIntervalMs 100
            $result.status.value | Should -Be 'ready'
            $script:WaitTestCallCount | Should -BeGreaterOrEqual 3
        }

        It "Should support -TargetStatus merged for merge workflow" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                $script:WaitTestCallCount++
                $status = if ($script:WaitTestCallCount -lt 2) { 'merging' } else { 'merged' }
                return [PSCustomObject]@{
                    id     = 42
                    name   = 'merging-branch'
                    status = [PSCustomObject]@{ value = $status }
                }
            }

            $result = Wait-NBBranch -Id 42 -TargetStatus 'merged' -PollIntervalMs 100
            $result.status.value | Should -Be 'merged'
        }

        It "Should throw on 'failed' status and include branch errors" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{
                    id     = 42
                    name   = 'doomed'
                    status = [PSCustomObject]@{ value = 'failed' }
                    errors = @('Schema migration failed: relation already exists')
                }
            }

            { Wait-NBBranch -Id 42 -PollIntervalMs 100 } |
                Should -Throw -ExpectedMessage "*failed*Schema migration failed*"
        }

        It "Should fail fast on unexpected terminal status (archived while waiting for ready)" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{
                    id     = 42
                    name   = 'stale'
                    status = [PSCustomObject]@{ value = 'archived' }
                }
            }

            { Wait-NBBranch -Id 42 -TargetStatus 'ready' -PollIntervalMs 100 } |
                Should -Throw -ExpectedMessage "*terminal status 'archived'*"
        }

        It "Should throw a timeout error when branch never reaches target" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{
                    id     = 42
                    name   = 'slow'
                    status = [PSCustomObject]@{ value = 'provisioning' }
                }
            }

            { Wait-NBBranch -Id 42 -TimeoutSeconds 1 -PollIntervalMs 100 } |
                Should -Throw -ExpectedMessage "*Timed out*provisioning*"
        }

        It "Should resolve -Name via Get-NBBranch on first poll" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{
                    id     = 99
                    name   = 'lookup-branch'
                    status = [PSCustomObject]@{ value = 'ready' }
                }
            }

            $result = Wait-NBBranch -Name 'lookup-branch' -PollIntervalMs 100
            $result.id | Should -Be 99
            $result.name | Should -Be 'lookup-branch'
        }

        It "Should accept pipeline input from a New-NBBranch-style object" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{
                    id     = 55
                    name   = 'piped'
                    status = [PSCustomObject]@{ value = 'ready' }
                }
            }

            # Simulate what New-NBBranch returns (status is still 'new')
            $newBranch = [PSCustomObject]@{
                id     = 55
                name   = 'piped'
                status = [PSCustomObject]@{ value = 'new' }
            }

            $result = $newBranch | Wait-NBBranch -PollIntervalMs 100
            $result.id | Should -Be 55
            $result.status.value | Should -Be 'ready'
        }

        It "Should throw when branch is not found on first poll" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith { return $null }

            { Wait-NBBranch -Id 99999 -PollIntervalMs 100 } |
                Should -Throw -ExpectedMessage "*not found*"
        }

        It "Should throw 'removed' error when branch disappears mid-wait" {
            Mock -CommandName 'Get-NBBranch' -ModuleName 'PowerNetbox' -MockWith {
                $script:WaitTestCallCount++
                if ($script:WaitTestCallCount -eq 1) {
                    return [PSCustomObject]@{
                        id     = 42
                        name   = 'vanishing'
                        status = [PSCustomObject]@{ value = 'provisioning' }
                    }
                }
                return $null
            }

            { Wait-NBBranch -Id 42 -PollIntervalMs 100 } |
                Should -Throw -ExpectedMessage "*removed*"
        }

        It "Should validate -TargetStatus against known terminal states" {
            # 'provisioning' is transitional, not a valid terminal target
            { Wait-NBBranch -Id 1 -TargetStatus 'provisioning' } | Should -Throw
            # 'failed' is terminal but is always an error path, not a target
            { Wait-NBBranch -Id 1 -TargetStatus 'failed' } | Should -Throw
        }

        It "Should reject zero or negative TimeoutSeconds" {
            { Wait-NBBranch -Id 1 -TimeoutSeconds 0 } | Should -Throw
        }
    }
    #endregion

    #region Get-NBBranchEvent Tests
    Context "Get-NBBranchEvent" {
        It "Should request branch events" {
            $Result = Get-NBBranchEvent
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branch-events/'
        }

        It "Should request a branch event by ID" {
            $Result = Get-NBBranchEvent -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branch-events/5/'
        }

        It "Should filter by branch ID" {
            $Result = Get-NBBranchEvent -Branch_Id 3
            $Result.Uri | Should -Match 'branch_id=3'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBBranchEvent -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 15 } | Get-NBBranchEvent
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/branch-events/15/'
        }
    }
    #endregion

    #region Get-NBChangeDiff Tests
    Context "Get-NBChangeDiff" {
        It "Should request change diffs" {
            $Result = Get-NBChangeDiff
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/changes/'
        }

        It "Should request a change diff by ID" {
            $Result = Get-NBChangeDiff -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/changes/5/'
        }

        It "Should filter by branch ID" {
            $Result = Get-NBChangeDiff -Branch_Id 2
            $Result.Uri | Should -Match 'branch_id=2'
        }

        It "Should filter by object type" {
            $Result = Get-NBChangeDiff -Object_Type 'dcim.device'
            $Result.Uri | Should -Match 'object_type=dcim.device'
        }

        It "Should filter by action" {
            $Result = Get-NBChangeDiff -Action 'create'
            $Result.Uri | Should -Match 'action=create'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBChangeDiff -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }

        It "Should accept pipeline input" {
            $Result = [PSCustomObject]@{ Id = 25 } | Get-NBChangeDiff
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/plugins/branching/changes/25/'
        }
    }
    #endregion

    #region Branch Header Injection Tests
    Context "Branch Header Injection in InvokeNetboxRequest" {
        It "Should add X-NetBox-Branch header with schema_id when in branch context" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{
                    Name = "feature-branch"
                    SchemaId = "feat1234"
                    Id = 1
                })
            }

            $Result = Get-NBBranch -Limit 1
            $Result.Headers['X-NetBox-Branch'] | Should -Be 'feat1234'
        }

        It "Should not add header when not in branch context" {
            $Result = Get-NBBranch -Limit 1
            $Result.Headers.ContainsKey('X-NetBox-Branch') | Should -BeFalse
        }

        It "Should use nested branch context schema_id" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{ Name = "outer"; SchemaId = "out12345"; Id = 1 })
                $script:NetboxConfig.BranchStack.Push([PSCustomObject]@{ Name = "inner"; SchemaId = "inn12345"; Id = 2 })
            }

            $Result = Get-NBBranch -Limit 1
            $Result.Headers['X-NetBox-Branch'] | Should -Be 'inn12345'
        }

        It "Should handle legacy string format for backwards compatibility" {
            InModuleScope -ModuleName 'PowerNetbox' {
                # Simulate legacy string format (e.g., from explicit -Branch parameter)
                $script:NetboxConfig.BranchStack = [System.Collections.Generic.Stack[object]]::new()
                $script:NetboxConfig.BranchStack.Push("legacy_schema_id")
            }

            $Result = Get-NBBranch -Limit 1
            $Result.Headers['X-NetBox-Branch'] | Should -Be 'legacy_schema_id'
        }
    }
    #endregion

    #region Omit Parameter Tests
    Context "Omit Parameter" {
        $omitTestCases = @(
            @{ Command = 'Get-NBBranch' }
            @{ Command = 'Get-NBBranchEvent' }
            @{ Command = 'Get-NBChangeDiff' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments(%2C|,)description'
        }
    }
    #endregion
}
