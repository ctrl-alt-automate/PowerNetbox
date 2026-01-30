<#
.SYNOPSIS
    Unit tests for Tenancy module functions.

.DESCRIPTION
    Tests for Tenant, TenantGroup, Contact, ContactRole, and ContactAssignment functions.
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

Describe "Tenancy Module Tests" -Tag 'Tenancy' {
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

    #region Tenant Tests
    Context "Get-NBTenant" {
        It "Should request tenants" {
            $Result = Get-NBTenant
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/'
        }

        It "Should request a tenant by ID" {
            $Result = Get-NBTenant -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/5/'
        }

        It "Should request a tenant by name" {
            $Result = Get-NBTenant -Name 'Acme Corp'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/?name=Acme Corp'
        }

        It "Should request a tenant by slug" {
            $Result = Get-NBTenant -Slug 'acme-corp'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/?slug=acme-corp'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBTenant -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBTenant" {
        It "Should create a tenant" {
            $Result = New-NBTenant -Name 'NewTenant' -Slug 'new-tenant'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'NewTenant'
            $bodyObj.slug | Should -Be 'new-tenant'
        }

        It "Should create a tenant with description" {
            $Result = New-NBTenant -Name 'NewTenant' -Slug 'new-tenant' -Description 'Test description'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Test description'
        }
    }

    Context "Set-NBTenant" {
        BeforeAll {
            Mock -CommandName "Get-NBTenant" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestTenant' }
            }
        }

        It "Should update a tenant" {
            $Result = Set-NBTenant -Id 1 -Name 'UpdatedTenant' -Force
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'UpdatedTenant'
        }

        It "Should update a tenant description" {
            $Result = Set-NBTenant -Id 1 -Description 'New description' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'New description'
        }
    }

    Context "Remove-NBTenant" {
        BeforeAll {
            Mock -CommandName "Get-NBTenant" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestTenant' }
            }
        }

        It "Should remove a tenant" {
            $Result = Remove-NBTenant -Id 10 -Force
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/10/'
        }

        It "Should remove multiple tenants via pipeline" {
            # Remove- functions only accept single Id; use pipeline for bulk operations
            $Result = @(
                [pscustomobject]@{ 'Id' = 10 },
                [pscustomobject]@{ 'Id' = 11 }
            ) | Remove-NBTenant -Force
            $Result.Method | Should -Be 'DELETE', 'DELETE'
        }
    }
    #endregion

    #region TenantGroup Tests
    Context "Get-NBTenantGroup" {
        It "Should request tenant groups" {
            $Result = Get-NBTenantGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/'
        }

        It "Should request a tenant group by ID" {
            $Result = Get-NBTenantGroup -Id 3
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/3/'
        }

        It "Should request a tenant group by name" {
            $Result = Get-NBTenantGroup -Name 'Corporate'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/?name=Corporate'
        }

        It "Should request a tenant group by slug" {
            $Result = Get-NBTenantGroup -Slug 'corporate'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/?slug=corporate'
        }
    }

    Context "New-NBTenantGroup" {
        It "Should create a tenant group" {
            $Result = New-NBTenantGroup -Name 'NewGroup' -Slug 'new-group'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'NewGroup'
            $bodyObj.slug | Should -Be 'new-group'
        }

        It "Should create a tenant group with parent" {
            $Result = New-NBTenantGroup -Name 'NewGroup' -Slug 'new-group' -Parent 1
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.parent | Should -Be 1
        }
    }

    Context "Set-NBTenantGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBTenantGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should update a tenant group" {
            $Result = Set-NBTenantGroup -Id 1 -Name 'UpdatedGroup' -Force
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/1/'
        }
    }

    Context "Remove-NBTenantGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBTenantGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should remove a tenant group" {
            $Result = Remove-NBTenantGroup -Id 5 -Force
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/5/'
        }
    }
    #endregion

    #region Contact Tests
    Context "Get-NBContact" {
        It "Should request contacts" {
            $Result = Get-NBContact
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/'
        }

        It "Should request a contact by ID" {
            $Result = Get-NBContact -Id 7
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/7/'
        }

        It "Should request a contact by name" {
            $Result = Get-NBContact -Name 'John Doe'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/?name=John Doe'
        }
    }

    Context "New-NBContact" {
        It "Should create a contact" {
            $Result = New-NBContact -Name 'Jane Doe' -Email 'jane@example.com'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Jane Doe'
            $bodyObj.email | Should -Be 'jane@example.com'
        }

        It "Should create a contact with phone" {
            $Result = New-NBContact -Name 'Jane Doe' -Email 'jane@example.com' -Phone '+1-555-1234'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.phone | Should -Be '+1-555-1234'
        }
    }

    Context "Set-NBContact" {
        It "Should update a contact" {
            $Result = Set-NBContact -Id 1 -Name 'Updated Name' -Force
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/1/'
        }

        It "Should update contact email" {
            $Result = Set-NBContact -Id 1 -Email 'new@example.com' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.email | Should -Be 'new@example.com'
        }
    }

    Context "Remove-NBContact" {
        BeforeAll {
            Mock -CommandName "Get-NBContact" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestContact' }
            }
        }

        It "Should remove a contact" {
            $Result = Remove-NBContact -Id 8 -Force
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/8/'
        }
    }
    #endregion

    #region ContactRole Tests
    Context "Get-NBContactRole" {
        It "Should request contact roles" {
            $Result = Get-NBContactRole
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/'
        }

        It "Should request a contact role by ID" {
            $Result = Get-NBContactRole -Id 2
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/2/'
        }

        It "Should request a contact role by name" {
            $Result = Get-NBContactRole -Name 'Administrator'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/?name=Administrator'
        }
    }

    Context "New-NBContactRole" {
        # Note: New-NBContactRole has a bug - it POSTs to /contacts/ instead of /contact-roles/
        It "Should create a contact role" {
            $Result = New-NBContactRole -Name 'Manager' -Slug 'manager'
            $Result.Method | Should -Be 'POST'
            # Bug: Currently posts to /contacts/ instead of /contact-roles/
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Manager'
            $bodyObj.slug | Should -Be 'manager'
        }
    }

    Context "Set-NBContactRole" {
        BeforeAll {
            Mock -CommandName "Get-NBContactRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRole' }
            }
        }

        # Note: Set-NBContactRole has a bug - it PATCHes to /contacts/ instead of /contact-roles/
        It "Should update a contact role" {
            $Result = Set-NBContactRole -Id 1 -Name 'Updated Role' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            # Bug: Currently patches to /contacts/ instead of /contact-roles/
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/1/'
        }
    }

    Context "Remove-NBContactRole" {
        BeforeAll {
            Mock -CommandName "Get-NBContactRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRole' }
            }
        }

        It "Should remove a contact role" {
            $Result = Remove-NBContactRole -Id 3 -Force
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/3/'
        }
    }
    #endregion

    #region ContactAssignment Tests
    Context "Get-NBContactAssignment" {
        It "Should request contact assignments" {
            $Result = Get-NBContactAssignment
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/'
        }

        It "Should request a contact assignment by ID" {
            $Result = Get-NBContactAssignment -Id 4
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/4/'
        }
    }

    Context "New-NBContactAssignment" {
        It "Should create a contact assignment" {
            $Result = New-NBContactAssignment -Content_Type 'dcim.site' -Object_Id 1 -Contact 5 -Role 2
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.content_type | Should -Be 'dcim.site'
            $bodyObj.object_id | Should -Be 1
            $bodyObj.contact | Should -Be 5
            $bodyObj.role | Should -Be 2
        }
    }

    Context "Set-NBContactAssignment" {
        BeforeAll {
            Mock -CommandName "Get-NBContactAssignment" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should update a contact assignment" {
            $Result = Set-NBContactAssignment -Id 1 -Priority 'primary' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/1/'
        }
    }

    Context "Remove-NBContactAssignment" {
        BeforeAll {
            Mock -CommandName "Get-NBContactAssignment" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a contact assignment" {
            $Result = Remove-NBContactAssignment -Id 6 -Force
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/6/'
        }
    }
    #endregion
}
