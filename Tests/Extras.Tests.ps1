<#
.SYNOPSIS
    Unit tests for Extras module functions.

.DESCRIPTION
    Tests for Tags, CustomFields, CustomFieldChoiceSets, ConfigContexts, Webhooks,
    JournalEntries, ExportTemplates, SavedFilters, Bookmarks, EventRules, CustomLinks,
    and ImageAttachments functions.
#>

param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "Extras Module Tests" -Tag 'Extras' {
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

    #region Tag Tests
    Context "Get-NBTag" {
        It "Should request tags" {
            $Result = Get-NBTag
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/tags/'
        }

        It "Should request a tag by ID" {
            $Result = Get-NBTag -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/tags/5/'
        }

        It "Should request a tag by name" {
            $Result = Get-NBTag -Name 'Production'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/tags/?name=Production'
        }

        It "Should request a tag by slug" {
            $Result = Get-NBTag -Slug 'production'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/tags/?slug=production'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBTag -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "Get-NBTag -All/-PageSize passthrough" {
        It "Should pass -All switch to InvokeNetboxRequest" {
            Get-NBTag -All
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $All -eq $true
            }
        }

        It "Should pass -PageSize to InvokeNetboxRequest" {
            Get-NBTag -All -PageSize 500
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $PageSize -eq 500
            }
        }
    }

    Context "New-NBTag" {
        It "Should create a tag" {
            $Result = New-NBTag -Name 'Development' -Slug 'development'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/tags/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Development'
            $bodyObj.slug | Should -Be 'development'
        }

        It "Should create a tag with color" {
            $Result = New-NBTag -Name 'Critical' -Slug 'critical' -Color 'ff0000'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.color | Should -Be 'ff0000'
        }

        It "Should create a tag with description" {
            $Result = New-NBTag -Name 'Test' -Slug 'test' -Description 'Test environment'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Test environment'
        }
    }

    Context "Set-NBTag" {
        It "Should update a tag" {
            $Result = Set-NBTag -Id 1 -Name 'Updated Tag' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/extras/tags/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Updated Tag'
        }

        It "Should update tag color" {
            $Result = Set-NBTag -Id 1 -Color '00ff00' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.color | Should -Be '00ff00'
        }
    }

    Context "Remove-NBTag" {
        BeforeAll {
            Mock -CommandName "Get-NBTag" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestTag' }
            }
        }

        It "Should remove a tag" {
            $Result = Remove-NBTag -Id 10 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/extras/tags/10/'
        }
    }
    #endregion

    #region CustomField Tests
    Context "Get-NBCustomField" {
        It "Should request custom fields" {
            $Result = Get-NBCustomField
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-fields/'
        }

        It "Should request a custom field by ID" {
            $Result = Get-NBCustomField -Id 3
            $Result.Uri | Should -Match '/api/extras/custom.fields/3/'
        }

        It "Should request a custom field by name" {
            $Result = Get-NBCustomField -Name 'asset_tag'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-fields/?name=asset_tag'
        }
    }

    Context "New-NBCustomField" {
        It "Should create a custom field" {
            $Result = New-NBCustomField -Name 'serial_number' -Type 'text' -Object_Types 'dcim.device'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-fields/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'serial_number'
            $bodyObj.type | Should -Be 'text'
        }

        It "Should create a custom field with label" {
            $Result = New-NBCustomField -Name 'cost' -Type 'integer' -Label 'Purchase Cost' -Object_Types 'dcim.device'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.label | Should -Be 'Purchase Cost'
        }
    }

    Context "Set-NBCustomField" {
        It "Should update a custom field" {
            $Result = Set-NBCustomField -Id 1 -Label 'Updated Label' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/extras/custom.fields/1/'
        }
    }

    Context "Remove-NBCustomField" {
        BeforeAll {
            Mock -CommandName "Get-NBCustomField" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestField' }
            }
        }

        It "Should remove a custom field" {
            $Result = Remove-NBCustomField -Id 5 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/custom.fields/5/'
        }
    }
    #endregion

    #region CustomFieldChoiceSet Tests
    Context "Get-NBCustomFieldChoiceSet" {
        It "Should request custom field choice sets" {
            $Result = Get-NBCustomFieldChoiceSet
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-field-choice-sets/'
        }

        It "Should request a choice set by ID" {
            $Result = Get-NBCustomFieldChoiceSet -Id 7
            $Result.Uri | Should -Match '/api/extras/custom.field.choice.sets/7/'
        }

        It "Should request a choice set by name" {
            $Result = Get-NBCustomFieldChoiceSet -Name 'Status Options'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-field-choice-sets/?name=Status%20Options'
        }
    }

    Context "New-NBCustomFieldChoiceSet" {
        It "Should create a custom field choice set" {
            $Result = New-NBCustomFieldChoiceSet -Name 'Priority' -Extra_Choices @(@('high', 'High'), @('low', 'Low'))
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-field-choice-sets/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Priority'
        }
    }

    Context "Set-NBCustomFieldChoiceSet" {
        It "Should update a custom field choice set" {
            $Result = Set-NBCustomFieldChoiceSet -Id 1 -Name 'Updated Choices' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/extras/custom.field.choice.sets/1/'
        }
    }

    Context "Remove-NBCustomFieldChoiceSet" {
        BeforeAll {
            Mock -CommandName "Get-NBCustomFieldChoiceSet" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestChoiceSet' }
            }
        }

        It "Should remove a custom field choice set" {
            $Result = Remove-NBCustomFieldChoiceSet -Id 8 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/custom.field.choice.sets/8/'
        }
    }
    #endregion

    #region ConfigContext Tests
    Context "Get-NBConfigContext" {
        It "Should request config contexts" {
            $Result = Get-NBConfigContext
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/config-contexts/'
        }

        It "Should request a config context by ID" {
            $Result = Get-NBConfigContext -Id 4
            $Result.Uri | Should -Match '/api/extras/config.contexts/4/'
        }

        It "Should request a config context by name" {
            $Result = Get-NBConfigContext -Name 'DNS Servers'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/config-contexts/?name=DNS%20Servers'
        }
    }

    Context "New-NBConfigContext" {
        It "Should create a config context" {
            $Result = New-NBConfigContext -Name 'NTP Config' -Data @{ servers = @('10.0.0.1') }
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/config-contexts/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'NTP Config'
        }

        It "Should create a config context with weight" {
            $Result = New-NBConfigContext -Name 'Site Config' -Data @{ location = 'DC1' } -Weight 1000
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.weight | Should -Be 1000
        }
    }

    Context "Set-NBConfigContext" {
        It "Should update a config context" {
            $Result = Set-NBConfigContext -Id 1 -Name 'Updated Context' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/extras/config.contexts/1/'
        }
    }

    Context "Remove-NBConfigContext" {
        BeforeAll {
            Mock -CommandName "Get-NBConfigContext" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestContext' }
            }
        }

        It "Should remove a config context" {
            $Result = Remove-NBConfigContext -Id 6 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/config.contexts/6/'
        }
    }
    #endregion

    #region Webhook Tests
    Context "Get-NBWebhook" {
        It "Should request webhooks" {
            $Result = Get-NBWebhook
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/webhooks/'
        }

        It "Should request a webhook by ID" {
            $Result = Get-NBWebhook -Id 9
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/webhooks/9/'
        }

        It "Should request a webhook by name" {
            $Result = Get-NBWebhook -Name 'Slack Notification'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/webhooks/?name=Slack%20Notification'
        }
    }

    Context "New-NBWebhook" {
        It "Should create a webhook" {
            $Result = New-NBWebhook -Name 'Teams Alert' -Payload_Url 'https://webhook.example.com'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/webhooks/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Teams Alert'
            $bodyObj.payload_url | Should -Be 'https://webhook.example.com'
        }
    }

    Context "Set-NBWebhook" {
        It "Should update a webhook" {
            $Result = Set-NBWebhook -Id 1 -Name 'Updated Webhook' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/extras/webhooks/1/'
        }
    }

    Context "Remove-NBWebhook" {
        BeforeAll {
            Mock -CommandName "Get-NBWebhook" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestWebhook' }
            }
        }

        It "Should remove a webhook" {
            $Result = Remove-NBWebhook -Id 11 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/extras/webhooks/11/'
        }
    }
    #endregion

    #region JournalEntry Tests
    Context "Get-NBJournalEntry" {
        It "Should request journal entries" {
            $Result = Get-NBJournalEntry
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/journal-entries/'
        }

        It "Should request a journal entry by ID" {
            $Result = Get-NBJournalEntry -Id 12
            $Result.Uri | Should -Match '/api/extras/journal.entries/12/'
        }
    }

    Context "New-NBJournalEntry" {
        It "Should create a journal entry" {
            $Result = New-NBJournalEntry -Assigned_Object_Type 'dcim.device' -Assigned_Object_Id 1 -Comments 'Test entry'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/journal-entries/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.comments | Should -Be 'Test entry'
        }

        It "Should create a journal entry with kind" {
            $Result = New-NBJournalEntry -Assigned_Object_Type 'dcim.device' -Assigned_Object_Id 1 -Comments 'Issue' -Kind 'warning'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.kind | Should -Be 'warning'
        }
    }

    Context "Set-NBJournalEntry" {
        It "Should update a journal entry" {
            $Result = Set-NBJournalEntry -Id 1 -Comments 'Updated comment' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/extras/journal.entries/1/'
        }
    }

    Context "Remove-NBJournalEntry" {
        BeforeAll {
            Mock -CommandName "Get-NBJournalEntry" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a journal entry" {
            $Result = Remove-NBJournalEntry -Id 13 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/journal.entries/13/'
        }
    }
    #endregion

    #region ExportTemplate Tests
    Context "Get-NBExportTemplate" {
        It "Should request export templates" {
            $Result = Get-NBExportTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/export-templates/'
        }

        It "Should request an export template by ID" {
            $Result = Get-NBExportTemplate -Id 14
            $Result.Uri | Should -Match '/api/extras/export.templates/14/'
        }

        It "Should request an export template by name" {
            $Result = Get-NBExportTemplate -Name 'Device CSV'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/export-templates/?name=Device%20CSV'
        }
    }

    Context "New-NBExportTemplate" {
        It "Should create an export template" {
            $Result = New-NBExportTemplate -Name 'Site Export' -Object_Types 'dcim.site' -Template_Code '{{ site.name }}'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/export-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Site Export'
        }
    }

    Context "Set-NBExportTemplate" {
        It "Should update an export template" {
            $Result = Set-NBExportTemplate -Id 1 -Name 'Updated Template' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/extras/export.templates/1/'
        }
    }

    Context "Remove-NBExportTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBExportTemplate" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestTemplate' }
            }
        }

        It "Should remove an export template" {
            $Result = Remove-NBExportTemplate -Id 15 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/export.templates/15/'
        }
    }
    #endregion

    #region SavedFilter Tests
    Context "Get-NBSavedFilter" {
        It "Should request saved filters" {
            $Result = Get-NBSavedFilter
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/saved-filters/'
        }

        It "Should request a saved filter by ID" {
            $Result = Get-NBSavedFilter -Id 16
            $Result.Uri | Should -Match '/api/extras/saved.filters/16/'
        }

        It "Should request a saved filter by name" {
            $Result = Get-NBSavedFilter -Name 'Active Devices'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/saved-filters/?name=Active%20Devices'
        }
    }

    Context "New-NBSavedFilter" {
        It "Should create a saved filter" {
            $Result = New-NBSavedFilter -Name 'Server Filter' -Slug 'server-filter' -Object_Types 'dcim.device' -Parameters @{ role = 'server' }
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/saved-filters/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Server Filter'
            $bodyObj.slug | Should -Be 'server-filter'
        }
    }

    Context "Set-NBSavedFilter" {
        It "Should update a saved filter" {
            $Result = Set-NBSavedFilter -Id 1 -Name 'Updated Filter' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/extras/saved.filters/1/'
        }
    }

    Context "Remove-NBSavedFilter" {
        BeforeAll {
            Mock -CommandName "Get-NBSavedFilter" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestFilter' }
            }
        }

        It "Should remove a saved filter" {
            $Result = Remove-NBSavedFilter -Id 17 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/saved.filters/17/'
        }
    }
    #endregion

    #region Bookmark Tests
    Context "Get-NBBookmark" {
        It "Should request bookmarks" {
            $Result = Get-NBBookmark
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/bookmarks/'
        }

        It "Should request a bookmark by ID" {
            $Result = Get-NBBookmark -Id 18
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/bookmarks/18/'
        }
    }

    Context "New-NBBookmark" {
        It "Should create a bookmark" {
            $Result = New-NBBookmark -Object_Type 'dcim.device' -Object_Id 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/bookmarks/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.object_type | Should -Be 'dcim.device'
            $bodyObj.object_id | Should -Be 1
        }
    }

    Context "Remove-NBBookmark" {
        BeforeAll {
            Mock -CommandName "Get-NBBookmark" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a bookmark" {
            $Result = Remove-NBBookmark -Id 19 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/extras/bookmarks/19/'
        }
    }
    #endregion

    #region EventRule Tests
    Context "Get-NBEventRule" {
        It "Should request event rules" {
            $Result = Get-NBEventRule
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/event-rules/'
        }

        It "Should request an event rule by ID" {
            $Result = Get-NBEventRule -Id 20
            $Result.Uri | Should -Match '/api/extras/event.rules/20/'
        }

        It "Should request an event rule by name" {
            $Result = Get-NBEventRule -Name 'Device Created'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/event-rules/?name=Device%20Created'
        }
    }

    Context "New-NBEventRule" {
        It "Should create an event rule" {
            $Result = New-NBEventRule -Name 'Site Alert' -Object_Types 'dcim.site' -Type_Create $true -Action_Type 'webhook' -Action_Object_Id 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/event-rules/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Site Alert'
        }
    }

    Context "Set-NBEventRule" {
        It "Should update an event rule" {
            $Result = Set-NBEventRule -Id 1 -Name 'Updated Rule' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/extras/event.rules/1/'
        }
    }

    Context "Remove-NBEventRule" {
        BeforeAll {
            Mock -CommandName "Get-NBEventRule" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRule' }
            }
        }

        It "Should remove an event rule" {
            $Result = Remove-NBEventRule -Id 21 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/event.rules/21/'
        }
    }
    #endregion

    #region CustomLink Tests
    Context "Get-NBCustomLink" {
        It "Should request custom links" {
            $Result = Get-NBCustomLink
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-links/'
        }

        It "Should request a custom link by ID" {
            $Result = Get-NBCustomLink -Id 22
            $Result.Uri | Should -Match '/api/extras/custom.links/22/'
        }

        It "Should request a custom link by name" {
            $Result = Get-NBCustomLink -Name 'Documentation'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-links/?name=Documentation'
        }
    }

    Context "New-NBCustomLink" {
        It "Should create a custom link" {
            $Result = New-NBCustomLink -Name 'Wiki' -Object_Types 'dcim.device' -Link_Text 'View Wiki' -Link_Url 'https://wiki.example.com/{{ obj.name }}'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/custom-links/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Wiki'
            $bodyObj.link_text | Should -Be 'View Wiki'
        }
    }

    Context "Set-NBCustomLink" {
        It "Should update a custom link" {
            $Result = Set-NBCustomLink -Id 1 -Name 'Updated Link' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/extras/custom.links/1/'
        }
    }

    Context "Remove-NBCustomLink" {
        BeforeAll {
            Mock -CommandName "Get-NBCustomLink" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestLink' }
            }
        }

        It "Should remove a custom link" {
            $Result = Remove-NBCustomLink -Id 23 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/custom.links/23/'
        }
    }
    #endregion

    #region ImageAttachment Tests
    Context "Get-NBImageAttachment" {
        It "Should request image attachments" {
            $Result = Get-NBImageAttachment
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/extras/image-attachments/'
        }

        It "Should request an image attachment by ID" {
            $Result = Get-NBImageAttachment -Id 24
            $Result.Uri | Should -Match '/api/extras/image.attachments/24/'
        }
    }

    Context "New-NBImageAttachment" {
        BeforeAll {
            # New-NBImageAttachment bypasses InvokeNetboxRequest (uses Invoke-RestMethod directly)
            # Mock the helpers it calls and Invoke-RestMethod
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith {
                return @{}
            }
            Mock -CommandName 'Get-NBRequestHeaders' -ModuleName 'PowerNetbox' -MockWith {
                return @{ 'Authorization' = 'Bearer test-token' }
            }
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return [pscustomobject]@{
                    id          = 1
                    url         = 'https://netbox.domain.com/api/extras/image-attachments/1/'
                    object_type = 'dcim.device'
                    object_id   = 42
                    image       = '/media/image-attachments/test.png'
                }
            }

            # Create a temporary test image file
            $script:TestImagePath = Join-Path $TestDrive 'test-image.png'
            [byte[]]$pngBytes = @(137, 80, 78, 71, 13, 10, 26, 10)  # PNG magic bytes
            [System.IO.File]::WriteAllBytes($script:TestImagePath, $pngBytes)
        }

        It "Should have mandatory Object_Type parameter" {
            $cmd = Get-Command New-NBImageAttachment
            $cmd.Parameters['Object_Type'].Attributes.Mandatory | Should -Contain $true
        }

        It "Should have mandatory Object_Id parameter" {
            $cmd = Get-Command New-NBImageAttachment
            $cmd.Parameters['Object_Id'].Attributes.Mandatory | Should -Contain $true
        }

        It "Should have mandatory ImagePath parameter" {
            $cmd = Get-Command New-NBImageAttachment
            $cmd.Parameters['ImagePath'].Attributes.Mandatory | Should -Contain $true
        }

        It "Should accept Object_Id from pipeline via Id alias" {
            $cmd = Get-Command New-NBImageAttachment
            $param = $cmd.Parameters['Object_Id']
            $param.Aliases | Should -Contain 'Id'
            $pipeAttr = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $pipeAttr.ValueFromPipelineByPropertyName | Should -Contain $true
        }

        It "Should validate Name max length of 50" {
            $cmd = Get-Command New-NBImageAttachment
            $validateLength = $cmd.Parameters['Name'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateLengthAttribute] }
            $validateLength | Should -Not -BeNullOrEmpty
            $validateLength.MaxLength | Should -Be 50
        }

        It "Should validate Description max length of 200" {
            $cmd = Get-Command New-NBImageAttachment
            $validateLength = $cmd.Parameters['Description'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateLengthAttribute] }
            $validateLength | Should -Not -BeNullOrEmpty
            $validateLength.MaxLength | Should -Be 200
        }

        It "Should throw when image file does not exist" {
            { New-NBImageAttachment -Object_Type 'dcim.device' -Object_Id 1 -ImagePath '/nonexistent/fake.png' } | Should -Throw
        }

        It "Should not upload when WhatIf is specified" {
            New-NBImageAttachment -Object_Type 'dcim.device' -Object_Id 42 -ImagePath $script:TestImagePath -WhatIf
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 0 -Scope 'It' -ModuleName 'PowerNetbox'
        }

        It "Should support ShouldProcess" {
            $cmd = Get-Command New-NBImageAttachment
            $cmd.Parameters.Keys | Should -Contain 'Confirm'
            $cmd.Parameters.Keys | Should -Contain 'WhatIf'
        }
    }

    Context "Remove-NBImageAttachment" {
        BeforeAll {
            Mock -CommandName "Get-NBImageAttachment" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove an image attachment" {
            $Result = Remove-NBImageAttachment -Id 25 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/extras/image.attachments/25/'
        }
    }
    #endregion

    #region All/PageSize Passthrough Tests
    Context "All/PageSize Passthrough" {
        $allPageSizeTestCases = @(
            @{ Command = 'Get-NBBookmark' }
            @{ Command = 'Get-NBConfigContext' }
            @{ Command = 'Get-NBCustomField' }
            @{ Command = 'Get-NBCustomFieldChoiceSet' }
            @{ Command = 'Get-NBCustomLink' }
            @{ Command = 'Get-NBEventRule' }
            @{ Command = 'Get-NBExportTemplate' }
            @{ Command = 'Get-NBImageAttachment' }
            @{ Command = 'Get-NBJournalEntry' }
            @{ Command = 'Get-NBSavedFilter' }
            @{ Command = 'Get-NBWebhook' }
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
            @{ Command = 'Get-NBBookmark' }
            @{ Command = 'Get-NBConfigContext' }
            @{ Command = 'Get-NBCustomField' }
            @{ Command = 'Get-NBCustomFieldChoiceSet' }
            @{ Command = 'Get-NBCustomLink' }
            @{ Command = 'Get-NBEventRule' }
            @{ Command = 'Get-NBExportTemplate' }
            @{ Command = 'Get-NBImageAttachment' }
            @{ Command = 'Get-NBJournalEntry' }
            @{ Command = 'Get-NBSavedFilter' }
            @{ Command = 'Get-NBTag' }
            @{ Command = 'Get-NBWebhook' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion
}
