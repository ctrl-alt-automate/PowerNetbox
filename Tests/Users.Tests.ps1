<#
.SYNOPSIS
    Unit tests for Users module functions.

.DESCRIPTION
    Tests for Users, Groups, Tokens, and Permissions functions.
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

Describe "Users Module Tests" -Tag 'Users' {
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
        }
    }

    #region User Tests
    Context "Get-NBUser" {
        It "Should request users" {
            $Result = Get-NBUser
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/'
        }

        It "Should request a user by ID" {
            $Result = Get-NBUser -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/5/'
        }

        It "Should request a user by username" {
            $Result = Get-NBUser -Username 'admin'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/?username=admin'
        }

        It "Should request users by email" {
            $Result = Get-NBUser -Email 'admin@example.com'
            $Result.Uri | Should -Match 'email=admin'
        }

        It "Should request users by active status" {
            $Result = Get-NBUser -Is_Active $true
            $Result.Uri | Should -Match 'is_active=True'
        }

        It "Should request superusers" {
            $Result = Get-NBUser -Is_Superuser $true
            $Result.Uri | Should -Match 'is_superuser=True'
        }

        It "Should request users by group ID" {
            $Result = Get-NBUser -Group_Id 3
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/?group_id=3'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBUser -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBUser" {
        It "Should create a user with required parameters" {
            $securePass = ConvertTo-SecureString "TestPass123" -AsPlainText -Force
            $Result = New-NBUser -Username 'testuser' -Password $securePass -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.username | Should -Be 'testuser'
            $bodyObj.password | Should -Be 'TestPass123'
        }

        It "Should create a user with all optional parameters" {
            $securePass = ConvertTo-SecureString "TestPass123" -AsPlainText -Force
            $Result = New-NBUser -Username 'fulluser' -Password $securePass -First_Name 'John' -Last_Name 'Doe' -Email 'john@example.com' -Is_Active $true -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.first_name | Should -Be 'John'
            $bodyObj.last_name | Should -Be 'Doe'
            $bodyObj.email | Should -Be 'john@example.com'
        }

        It "Should support -WhatIf" {
            $securePass = ConvertTo-SecureString "TestPass123" -AsPlainText -Force
            $Result = New-NBUser -Username 'whatifuser' -Password $securePass -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBUser" {
        It "Should update a user" {
            $Result = Set-NBUser -Id 1 -First_Name 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.first_name | Should -Be 'Updated'
        }

        It "Should update user active status" {
            $Result = Set-NBUser -Id 2 -Is_Active $false -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.is_active | Should -Be $false
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 15 } | Set-NBUser -First_Name 'Piped' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/15/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBUser -Id 1 -First_Name 'WhatIf' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBUser" {
        It "Should delete a user" {
            $Result = Remove-NBUser -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/1/'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 20 } | Remove-NBUser -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/users/20/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBUser -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Group Tests
    Context "Get-NBGroup" {
        It "Should request groups" {
            $Result = Get-NBGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/groups/'
        }

        It "Should request a group by ID" {
            $Result = Get-NBGroup -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/groups/5/'
        }

        It "Should request a group by name" {
            $Result = Get-NBGroup -Name 'Administrators'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/groups/?name=Administrators'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBGroup -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBGroup" {
        It "Should create a group" {
            $Result = New-NBGroup -Name 'TestGroup' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestGroup'
        }

        It "Should support -WhatIf" {
            $Result = New-NBGroup -Name 'WhatIfGroup' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBGroup" {
        It "Should update a group" {
            $Result = Set-NBGroup -Id 1 -Name 'UpdatedGroup' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/groups/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'UpdatedGroup'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 15 } | Set-NBGroup -Name 'Piped' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/groups/15/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBGroup -Id 1 -Name 'WhatIf' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBGroup" {
        It "Should delete a group" {
            $Result = Remove-NBGroup -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/groups/1/'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 20 } | Remove-NBGroup -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/groups/20/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBGroup -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Token Tests
    Context "Get-NBToken" {
        It "Should request tokens" {
            $Result = Get-NBToken
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/tokens/'
        }

        It "Should request a token by ID" {
            $Result = Get-NBToken -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/tokens/5/'
        }

        It "Should request tokens by user ID" {
            $Result = Get-NBToken -User_Id 3
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/tokens/?user_id=3'
        }

        It "Should request tokens by write enabled status" {
            $Result = Get-NBToken -Write_Enabled $true
            $Result.Uri | Should -Match 'write_enabled=True'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBToken -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBToken" {
        It "Should create a token" {
            $Result = New-NBToken -User 1 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/tokens/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.user | Should -Be 1
        }

        It "Should create a token with description" {
            $Result = New-NBToken -User 1 -Description 'API access token' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'API access token'
        }

        It "Should create a token with write enabled" {
            $Result = New-NBToken -User 1 -Write_Enabled $true -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.write_enabled | Should -Be $true
        }

        It "Should support -WhatIf" {
            $Result = New-NBToken -User 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBToken" {
        It "Should update a token" {
            $Result = Set-NBToken -Id 1 -Description 'Updated description' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/tokens/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Updated description'
        }

        It "Should update token write status" {
            $Result = Set-NBToken -Id 2 -Write_Enabled $false -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.write_enabled | Should -Be $false
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 15 } | Set-NBToken -Description 'Piped' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/tokens/15/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBToken -Id 1 -Description 'WhatIf' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBToken" {
        It "Should delete a token" {
            $Result = Remove-NBToken -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/tokens/1/'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 20 } | Remove-NBToken -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/tokens/20/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBToken -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Permission Tests
    Context "Get-NBPermission" {
        It "Should request permissions" {
            $Result = Get-NBPermission
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/permissions/'
        }

        It "Should request a permission by ID" {
            $Result = Get-NBPermission -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/permissions/5/'
        }

        It "Should request permissions by name" {
            $Result = Get-NBPermission -Name 'view_device'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/permissions/?name=view_device'
        }

        It "Should request permissions by enabled status" {
            $Result = Get-NBPermission -Enabled $true
            $Result.Uri | Should -Match 'enabled=True'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBPermission -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBPermission" {
        It "Should create a permission" {
            $Result = New-NBPermission -Name 'test-permission' -Object_Types @('dcim.device') -Actions @('view') -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/permissions/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'test-permission'
        }

        It "Should support -WhatIf" {
            $Result = New-NBPermission -Name 'whatif-permission' -Object_Types @('dcim.device') -Actions @('view') -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBPermission" {
        It "Should update a permission" {
            $Result = Set-NBPermission -Id 1 -Name 'updated-permission' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/permissions/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'updated-permission'
        }

        It "Should update permission enabled status" {
            $Result = Set-NBPermission -Id 2 -Enabled $false -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.enabled | Should -Be $false
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 15 } | Set-NBPermission -Name 'Piped' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/permissions/15/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBPermission -Id 1 -Name 'WhatIf' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBPermission" {
        It "Should delete a permission" {
            $Result = Remove-NBPermission -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/permissions/1/'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 20 } | Remove-NBPermission -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/permissions/20/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBPermission -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion
}
