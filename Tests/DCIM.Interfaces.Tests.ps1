param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    $script:TestPath = $PSScriptRoot
}

Describe "DCIM Interfaces Tests" -Tag 'DCIM', 'Interfaces' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
        }

        InModuleScope -ModuleName 'PowerNetbox' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Get-NBDCIMInterface" {
        It "Should request the default number of interfaces" {
            $Result = Get-NBDCIMInterface
            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/'
        }

        It "Should request with a limit and offset" {
            $Result = Get-NBDCIMInterface -Limit 10 -Offset 100
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=100'
        }

        It "Should request with enabled" {
            $Result = Get-NBDCIMInterface -Enabled $true
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/?enabled=True'
        }

        It "Should request with a type filter" {
            $Result = Get-NBDCIMInterface -Type '10gbase-t'
            $Result.Uri | Should -Match 'type=10gbase-t'
        }

        It "Should throw for invalid type" {
            # Type parameter has ValidateSet - invalid values throw at parameter binding
            { Get-NBDCIMInterface -Type 'Fake' } | Should -Throw
        }

        It "Should request devices that are mgmt only" {
            $Result = Get-NBDCIMInterface -MGMT_Only $True
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/?mgmt_only=True'
        }

        It "Should request with a name filter" {
            $Result = Get-NBDCIMInterface -Name "eth0"
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/?name=eth0'
        }

        It "Should request an interface by ID" {
            $Result = Get-NBDCIMInterface -Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match '/api/dcim/interfaces/10/'
        }

        It "Should request multiple interfaces by ID" {
            $Result = Get-NBDCIMInterface -Id 10, 12
            $Result | Should -HaveCount 2
            $Result[0].Uri | Should -Match '/api/dcim/interfaces/10/'
            $Result[1].Uri | Should -Match '/api/dcim/interfaces/12/'
        }

        It "Should request an interface from the pipeline" {
            $Result = [pscustomobject]@{ 'Id' = 1234 } | Get-NBDCIMInterface
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/1234/'
        }
    }

    Context "New-NBDCIMInterface" {
        It "Should add a basic interface to a device" {
            $Result = New-NBDCIMInterface -Device 111 -Name "TestInterface"
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestInterface'
            $bodyObj.device | Should -Be 111
        }

        It "Should add an interface with lots of properties" {
            $params = @{
                Device      = 123
                Name        = "TestInterface"
                Type        = '10gbase-t'
                MTU         = 9000
                MGMT_Only   = $true
                Description = 'Test Description'
                Mode        = 'Access'
            }
            $Result = New-NBDCIMInterface @params
            $Result.Method | Should -Be 'POST'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestInterface'
            $bodyObj.device | Should -Be 123
            $bodyObj.type | Should -Be '10gbase-t'
            $bodyObj.mtu | Should -Be 9000
            $bodyObj.mgmt_only | Should -Be $true
            $bodyObj.description | Should -Be 'Test Description'
        }

        It "Should add an interface with multiple tagged VLANs" {
            $Result = New-NBDCIMInterface -Device 444 -Name "TestInterface" -Mode 'Tagged' -Tagged_VLANs 1, 2, 3, 4
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestInterface'
            $bodyObj.device | Should -Be 444
            $bodyObj.tagged_vlans | Should -Be @(1, 2, 3, 4)
        }

        It "Should throw for invalid mode" {
            { New-NBDCIMInterface -Device 321 -Name "Test123" -Mode 'Fake' } | Should -Throw
        }

        It "Should throw for out of range VLAN" {
            { New-NBDCIMInterface -Device 321 -Name "Test123" -Untagged_VLAN 4100 } | Should -Throw
        }
    }

    Context "Set-NBDCIMInterface" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInterface" -ModuleName "PowerNetbox" -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should set an interface to a new name" {
            $Result = Set-NBDCIMInterface -Id 123 -Name "TestInterface"
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/123/'
            $Result.Body | Should -Be '{"name":"TestInterface"}'
        }

        It "Should set multiple interfaces from the pipeline" {
            $Result = @(
                [pscustomobject]@{ 'Id' = 1234 },
                [pscustomobject]@{ 'Id' = 4231 }
            ) | Set-NBDCIMInterface -Name "TestInterface"
            $Result.Method | Should -Be 'PATCH', 'PATCH'
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interfaces/1234/', 'https://netbox.domain.com/api/dcim/interfaces/4231/'
        }

        It "Should throw for invalid type" {
            # Type parameter has ValidateSet - invalid values throw at parameter binding
            { Set-NBDCIMInterface -Id 1234 -Type 'fake' } | Should -Throw
        }
    }

    Context "Remove-NBDCIMInterface" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInterface" -ModuleName "PowerNetbox" -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove an interface" {
            $Result = Remove-NBDCIMInterface -Id 10 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/10/'
        }

        It "Should remove multiple interfaces via pipeline" {
            # Remove- functions only accept single Id; use pipeline for bulk operations
            $Result = @(
                [pscustomobject]@{ 'Id' = 10 },
                [pscustomobject]@{ 'Id' = 12 }
            ) | Remove-NBDCIMInterface -Confirm:$false
            $Result.Method | Should -Be 'DELETE', 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/10/', 'https://netbox.domain.com/api/dcim/interfaces/12/'
        }

        It "Should remove interfaces from the pipeline" {
            $Result = @(
                [pscustomobject]@{ 'Id' = 30 },
                [pscustomobject]@{ 'Id' = 40 }
            ) | Remove-NBDCIMInterface -Confirm:$false
            $Result.Method | Should -Be 'DELETE', 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interfaces/30/', 'https://netbox.domain.com/api/dcim/interfaces/40/'
        }
    }

    Context "Get-NBDCIMInterfaceConnection" {
        It "Should request interface connections" {
            $Result = Get-NBDCIMInterfaceConnection
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/'
        }

        It "Should request connected interfaces" {
            $Result = Get-NBDCIMInterfaceConnection -Connection_Status 'Connected'
            # Status value is passed through to API as-is
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/?connection_status=Connected'
        }

        It "Should have ValidateSet for Connection_Status parameter" {
            # Connection_Status parameter now uses ValidateSet for type safety
            $cmd = Get-Command Get-NBDCIMInterfaceConnection
            $param = $cmd.Parameters['Connection_Status']
            $validateSet = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'connected'
        }

        It "Should request an interface connection by ID" {
            $Result = Get-NBDCIMInterfaceConnection -Id 7
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match '/api/dcim/interface-connections/7/'
        }
    }

    Context "New-NBDCIMInterfaceConnection" {
        It "Should add a new interface connection" {
            $Result = New-NBDCIMInterfaceConnection -Interface_A 21 -Interface_B 22
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.interface_a | Should -Be 21
            $bodyObj.interface_b | Should -Be 22
        }

        It "Should throw for invalid connection status" {
            # Connection_Status has ValidateSet, so invalid values throw
            { New-NBDCIMInterfaceConnection -Interface_A 21 -Interface_B 22 -Connection_Status 'fake' } | Should -Throw
        }
    }

    Context "Set-NBDCIMInterfaceConnection" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInterfaceConnection" -ModuleName 'PowerNetbox' -MockWith {
                [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should set an interface connection" {
            $Result = Set-NBDCIMInterfaceConnection -Id 123 -Interface_B 2 -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/interface-connections/123/'
            $Result.Body | Should -Be '{"interface_b":2}'
        }

        It "Should throw when trying to set multiple connections" {
            # Set- functions only accept single Id; this test verifies the validation works
            { Set-NBDCIMInterfaceConnection -Id 456, 789 -Interface_B 22 -Confirm:$false } | Should -Throw
        }
    }

    Context "Remove-NBDCIMInterfaceConnection" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInterfaceConnection" -ModuleName 'PowerNetbox' -MockWith {
                [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove an interface connection" {
            $Result = Remove-NBDCIMInterfaceConnection -Id 10 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/10/'
        }

        It "Should remove multiple interface connections via pipeline" {
            # Remove- functions only accept single Id; use pipeline for bulk operations
            $Result = @(
                [pscustomobject]@{ 'Id' = 10 },
                [pscustomobject]@{ 'Id' = 12 }
            ) | Remove-NBDCIMInterfaceConnection -Confirm:$false
            $Result.Method | Should -Be 'DELETE', 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/interface-connections/10/', 'https://netbox.domain.com/api/dcim/interface-connections/12/'
        }
    }

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBDCIMInterface'; Parameters = @{ Device = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMInterfaceConnection'; Parameters = @{ Interface_A = 1; Interface_B = 1 } }
            @{ Command = 'Set-NBDCIMInterface'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMInterfaceConnection'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMInterface'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMInterfaceConnection'; Parameters = @{ Id = 1 } }
        )

        It 'Should support -WhatIf for <Command>' -TestCases $whatIfTestCases {
            param($Command, $Parameters)
            $splat = $Parameters.Clone()
            $splat.Add('WhatIf', $true)
            $Result = & $Command @splat
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region All/PageSize Passthrough Tests
    Context "All/PageSize Passthrough" {
        $allPageSizeTestCases = @(
            @{ Command = 'Get-NBDCIMInterface' }
            @{ Command = 'Get-NBDCIMInterfaceConnection' }
        )

        It 'Should pass -All to InvokeNetboxRequest for <Command>' -TestCases $allPageSizeTestCases {
            param($Command, $Parameters)
            $splat = @{ All = $true }
            if ($Parameters) { $splat += $Parameters }
            & $Command @splat
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $All -eq $true
            }
        }

        It 'Should pass -PageSize to InvokeNetboxRequest for <Command>' -TestCases $allPageSizeTestCases {
            param($Command, $Parameters)
            $splat = @{ All = $true; PageSize = 500 }
            if ($Parameters) { $splat += $Parameters }
            & $Command @splat
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $PageSize -eq 500
            }
        }
    }
    #endregion

    #region Omit Parameter Tests
    Context "Omit Parameter" {
        $omitTestCases = @(
            @{ Command = 'Get-NBDCIMInterface' }
            @{ Command = 'Get-NBDCIMInterfaceConnection' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion
}
