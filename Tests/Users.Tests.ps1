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
        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
        }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    #region Deprecation Tests
    Context "Test-NBDeprecatedParameter" {
        It "Should return false when parameter is not used" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = Test-NBDeprecatedParameter -ParameterName 'Is_Staff' -DeprecatedInVersion '4.5.0' -BoundParameters @{}
                $result | Should -Be $false
            }
        }

        It "Should return true and warn when parameter is used on Netbox 4.5+" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
                $result = Test-NBDeprecatedParameter -ParameterName 'Is_Staff' -DeprecatedInVersion '4.5.0' -BoundParameters @{ Is_Staff = $true } -WarningVariable warnings -WarningAction SilentlyContinue
                $result | Should -Be $true
            }
        }

        It "Should return false when parameter is used on Netbox 4.4.x" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
                $result = Test-NBDeprecatedParameter -ParameterName 'Is_Staff' -DeprecatedInVersion '4.5.0' -BoundParameters @{ Is_Staff = $true }
                $result | Should -Be $false
            }
        }

        It "Should return false when version is not set" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = $null
                $result = Test-NBDeprecatedParameter -ParameterName 'Is_Staff' -DeprecatedInVersion '4.5.0' -BoundParameters @{ Is_Staff = $true }
                $result | Should -Be $false
            }
        }
    }

    Context "Is_Staff Deprecation" {
        It "Should include Is_Staff in request body on Netbox 4.4.x" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }
            $securePass = ConvertTo-SecureString "TestPass123" -AsPlainText -Force
            $Result = New-NBUser -Username 'testuser' -Password $securePass -Is_Staff $true -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.is_staff | Should -Be $true
        }

        It "Should exclude Is_Staff from request body on Netbox 4.5+" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
            }
            $securePass = ConvertTo-SecureString "TestPass123" -AsPlainText -Force
            $Result = New-NBUser -Username 'testuser' -Password $securePass -Is_Staff $true -Confirm:$false -WarningAction SilentlyContinue
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'is_staff'
        }

        It "Should exclude Is_Staff from Set-NBUser on Netbox 4.5+" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
            }
            $Result = Set-NBUser -Id 1 -Is_Staff $true -Confirm:$false -WarningAction SilentlyContinue
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'is_staff'
        }

        It "Should include Is_Staff in Set-NBUser on Netbox 4.4.x" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }
            $Result = Set-NBUser -Id 1 -Is_Staff $false -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.is_staff | Should -Be $false
        }
    }
    #endregion

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

        It "Should create a token with Enabled parameter (Netbox 4.5+)" {
            $Result = New-NBToken -User 1 -Enabled $true -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.enabled | Should -Be $true
        }

        It "Should create a disabled token" {
            $Result = New-NBToken -User 1 -Enabled $false -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.enabled | Should -Be $false
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

        It "Should update token enabled status (Netbox 4.5+)" {
            $Result = Set-NBToken -Id 3 -Enabled $false -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.enabled | Should -Be $false
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

    #region OwnerGroup Tests (Netbox 4.5+)
    Context "Get-NBOwnerGroup" {
        It "Should request owner groups" {
            $Result = Get-NBOwnerGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owner-groups/'
        }

        It "Should request an owner group by ID" {
            $Result = Get-NBOwnerGroup -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owner-groups/5/'
        }

        It "Should request an owner group by name" {
            $Result = Get-NBOwnerGroup -Name 'NetworkTeam'
            $Result.Uri | Should -Match 'name=NetworkTeam'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBOwnerGroup -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBOwnerGroup" {
        It "Should create an owner group" {
            $Result = New-NBOwnerGroup -Name 'TestGroup' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owner-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestGroup'
        }

        It "Should create an owner group with description" {
            $Result = New-NBOwnerGroup -Name 'TestGroup' -Description 'Test description' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Test description'
        }

        It "Should support -WhatIf" {
            $Result = New-NBOwnerGroup -Name 'WhatIfGroup' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBOwnerGroup" {
        It "Should update an owner group" {
            $Result = Set-NBOwnerGroup -Id 1 -Name 'UpdatedGroup' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owner-groups/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'UpdatedGroup'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 15 } | Set-NBOwnerGroup -Name 'Piped' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owner-groups/15/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBOwnerGroup -Id 1 -Name 'WhatIf' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBOwnerGroup" {
        It "Should delete an owner group" {
            $Result = Remove-NBOwnerGroup -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owner-groups/1/'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 20 } | Remove-NBOwnerGroup -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owner-groups/20/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBOwnerGroup -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Owner Tests (Netbox 4.5+)
    Context "Get-NBOwner" {
        It "Should request owners" {
            $Result = Get-NBOwner
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owners/'
        }

        It "Should request an owner by ID" {
            $Result = Get-NBOwner -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owners/5/'
        }

        It "Should request an owner by name" {
            $Result = Get-NBOwner -Name 'NetworkOps'
            $Result.Uri | Should -Match 'name=NetworkOps'
        }

        It "Should request owners by group ID" {
            $Result = Get-NBOwner -Group_Id 3
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owners/?group_id=3'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBOwner -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBOwner" {
        It "Should create an owner" {
            $Result = New-NBOwner -Name 'TestOwner' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owners/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestOwner'
        }

        It "Should create an owner with group" {
            $Result = New-NBOwner -Name 'TestOwner' -Group 1 -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.group | Should -Be 1
        }

        It "Should create an owner with users" {
            $Result = New-NBOwner -Name 'TestOwner' -Users 1, 2, 3 -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.users | Should -Contain 1
            $bodyObj.users | Should -Contain 2
            $bodyObj.users | Should -Contain 3
        }

        It "Should support -WhatIf" {
            $Result = New-NBOwner -Name 'WhatIfOwner' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBOwner" {
        It "Should update an owner" {
            $Result = Set-NBOwner -Id 1 -Name 'UpdatedOwner' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owners/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'UpdatedOwner'
        }

        It "Should update owner users" {
            $Result = Set-NBOwner -Id 1 -Users 4, 5 -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.users | Should -Contain 4
            $bodyObj.users | Should -Contain 5
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 15 } | Set-NBOwner -Name 'Piped' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owners/15/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBOwner -Id 1 -Name 'WhatIf' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBOwner" {
        It "Should delete an owner" {
            $Result = Remove-NBOwner -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owners/1/'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 20 } | Remove-NBOwner -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/users/owners/20/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBOwner -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region All/PageSize Passthrough Tests
    Context "All/PageSize Passthrough" {
        $allPageSizeTestCases = @(
            @{ Command = 'Get-NBGroup' }
            @{ Command = 'Get-NBOwner' }
            @{ Command = 'Get-NBOwnerGroup' }
            @{ Command = 'Get-NBPermission' }
            @{ Command = 'Get-NBToken' }
            @{ Command = 'Get-NBUser' }
        )

        It 'Should pass -All to InvokeNetboxRequest for <Command>' -TestCases $allPageSizeTestCases {
            param($Command)
            & $Command -All
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $All -eq $true
            }
        }

        It 'Should pass -PageSize to InvokeNetboxRequest for <Command>' -TestCases $allPageSizeTestCases {
            param($Command)
            & $Command -All -PageSize 500
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $PageSize -eq 500
            }
        }
    }
    #endregion

    #region Omit Parameter Tests
    Context "Omit Parameter" {
        $omitTestCases = @(
            @{ Command = 'Get-NBGroup' }
            @{ Command = 'Get-NBOwner' }
            @{ Command = 'Get-NBOwnerGroup' }
            @{ Command = 'Get-NBPermission' }
            @{ Command = 'Get-NBToken' }
            @{ Command = 'Get-NBUser' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion
}
