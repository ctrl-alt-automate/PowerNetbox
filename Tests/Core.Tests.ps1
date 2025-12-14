<#
.SYNOPSIS
    Unit tests for Core module functions.

.DESCRIPTION
    Tests for DataSources, DataFiles, Jobs, ObjectChanges, and ObjectTypes functions.
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

Describe "Core Module Tests" -Tag 'Core' {
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

    #region DataSource Tests
    Context "Get-NBDataSource" {
        It "Should request data sources" {
            $Result = Get-NBDataSource
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/'
        }

        It "Should request a data source by ID" {
            $Result = Get-NBDataSource -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/5/'
        }

        It "Should request a data source by name" {
            $Result = Get-NBDataSource -Name 'config-repo'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/?name=config-repo'
        }

        It "Should request a data source by type" {
            $Result = Get-NBDataSource -Type 'git'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/?type=git'
        }

        It "Should request with enabled filter" {
            $Result = Get-NBDataSource -Enabled $true
            $Result.Uri | Should -Match 'enabled=True'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBDataSource -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }

        It "Should accept pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 10 } | Get-NBDataSource
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/10/'
        }
    }

    Context "New-NBDataSource" {
        It "Should create a data source with required parameters" {
            $Result = New-NBDataSource -Name 'test-source' -Type 'git' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'test-source'
            $bodyObj.type | Should -Be 'git'
        }

        It "Should create a data source with source URL" {
            $Result = New-NBDataSource -Name 'config-repo' -Type 'git' -Source_Url 'https://github.com/example/configs.git' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.source_url | Should -Be 'https://github.com/example/configs.git'
        }

        It "Should create a data source with all optional parameters" {
            $Result = New-NBDataSource -Name 'full-source' -Type 'local' -Description 'Test source' -Enabled $true -Comments 'Test comments' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Test source'
            $bodyObj.enabled | Should -Be $true
            $bodyObj.comments | Should -Be 'Test comments'
        }

        It "Should validate Type parameter" {
            { New-NBDataSource -Name 'test' -Type 'invalid' -Confirm:$false } | Should -Throw
        }

        It "Should support -WhatIf" {
            $Result = New-NBDataSource -Name 'test-whatif' -Type 'local' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBDataSource" {
        It "Should update a data source" {
            $Result = Set-NBDataSource -Id 1 -Name 'updated-source' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'updated-source'
        }

        It "Should update multiple fields" {
            $Result = Set-NBDataSource -Id 2 -Enabled $false -Description 'Disabled source' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.enabled | Should -Be $false
            $bodyObj.description | Should -Be 'Disabled source'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 15 } | Set-NBDataSource -Name 'piped-source' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/15/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBDataSource -Id 1 -Name 'test-whatif' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBDataSource" {
        It "Should delete a data source" {
            $Result = Remove-NBDataSource -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/1/'
        }

        It "Should support pipeline input by property name" {
            $Result = [PSCustomObject]@{ Id = 20 } | Remove-NBDataSource -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-sources/20/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBDataSource -Id 1 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region DataFile Tests
    Context "Get-NBDataFile" {
        It "Should request data files" {
            $Result = Get-NBDataFile
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-files/'
        }

        It "Should request a data file by ID" {
            $Result = Get-NBDataFile -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-files/5/'
        }

        It "Should request data files by source ID" {
            $Result = Get-NBDataFile -Source_Id 10
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/data-files/?source_id=10'
        }

        It "Should request data files by path" {
            $Result = Get-NBDataFile -Path 'config/settings.yaml'
            $Result.Uri | Should -Match 'path=config'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBDataFile -Limit 25 -Offset 50
            $Result.Uri | Should -Match 'limit=25'
            $Result.Uri | Should -Match 'offset=50'
        }
    }
    #endregion

    #region Job Tests
    Context "Get-NBJob" {
        It "Should request jobs" {
            $Result = Get-NBJob
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/jobs/'
        }

        It "Should request a job by ID" {
            $Result = Get-NBJob -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/jobs/5/'
        }

        It "Should request jobs by status" {
            $Result = Get-NBJob -Status 'running'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/jobs/?status=running'
        }

        It "Should request jobs by name" {
            $Result = Get-NBJob -Name 'sync_data'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/jobs/?name=sync_data'
        }

        It "Should request jobs by user ID" {
            $Result = Get-NBJob -User_Id 3
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/jobs/?user_id=3'
        }

        It "Should validate Status parameter" {
            { Get-NBJob -Status 'invalid-status' } | Should -Throw
        }

        It "Should request with limit and offset" {
            $Result = Get-NBJob -Limit 100 -Offset 0
            $Result.Uri | Should -Match 'limit=100'
        }
    }
    #endregion

    #region ObjectChange Tests
    Context "Get-NBObjectChange" {
        It "Should request object changes" {
            $Result = Get-NBObjectChange
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-changes/'
        }

        It "Should request an object change by ID" {
            $Result = Get-NBObjectChange -Id 100
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-changes/100/'
        }

        It "Should request object changes by action" {
            $Result = Get-NBObjectChange -Action 'create'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-changes/?action=create'
        }

        It "Should request object changes by user ID" {
            $Result = Get-NBObjectChange -User_Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-changes/?user_id=5'
        }

        It "Should request object changes by username" {
            $Result = Get-NBObjectChange -User_Name 'admin'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-changes/?user_name=admin'
        }

        It "Should request object changes by object type and ID" {
            $Result = Get-NBObjectChange -Changed_Object_Type 'dcim.device' -Changed_Object_Id 50
            $Result.Uri | Should -Match 'changed_object_type=dcim.device'
            $Result.Uri | Should -Match 'changed_object_id=50'
        }

        It "Should validate Action parameter" {
            { Get-NBObjectChange -Action 'invalid' } | Should -Throw
        }

        It "Should request with limit and offset" {
            $Result = Get-NBObjectChange -Limit 50 -Offset 100
            $Result.Uri | Should -Match 'limit=50'
            $Result.Uri | Should -Match 'offset=100'
        }
    }
    #endregion

    #region ObjectType Tests
    Context "Get-NBObjectType" {
        It "Should request object types" {
            $Result = Get-NBObjectType
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-types/'
        }

        It "Should request an object type by ID" {
            $Result = Get-NBObjectType -Id 25
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-types/25/'
        }

        It "Should request object types by app label" {
            $Result = Get-NBObjectType -App_Label 'dcim'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-types/?app_label=dcim'
        }

        It "Should request object types by model" {
            $Result = Get-NBObjectType -Model 'device'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/core/object-types/?model=device'
        }

        It "Should request object types with combined filters" {
            $Result = Get-NBObjectType -App_Label 'ipam' -Model 'ipaddress'
            $Result.Uri | Should -Match 'app_label=ipam'
            $Result.Uri | Should -Match 'model=ipaddress'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBObjectType -Limit 200 -Offset 0
            $Result.Uri | Should -Match 'limit=200'
        }
    }
    #endregion
}
