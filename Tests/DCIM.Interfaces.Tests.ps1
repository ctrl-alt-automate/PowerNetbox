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

        It "Should request with a label filter" {
            $Result = Get-NBDCIMInterface -Label "mgmt"
            $Result.Uri | Should -Match 'label=mgmt'
        }

        It "Should throw for invalid type" {
            # Type parameter has ValidateSet - invalid values throw at parameter binding
            { Get-NBDCIMInterface -Type 'Fake' } | Should -Throw
        }

        It "Should accept new 4.5.6 type filter '1.6tbase-x-osfp1600'" {
            $Result = Get-NBDCIMInterface -Type '1.6tbase-x-osfp1600'
            $Result.Uri | Should -Match 'type=1.6tbase-x-osfp1600'
        }

        It "Should accept new 4.5.6 type filter '2.5gbase-x-sfp'" {
            $Result = Get-NBDCIMInterface -Type '2.5gbase-x-sfp'
            $Result.Uri | Should -Match 'type=2.5gbase-x-sfp'
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

        It "Should accept VLAN database IDs larger than 4094" {
            $Result = New-NBDCIMInterface -Device 321 -Name "Test123" -Untagged_VLAN 14402
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.untagged_vlan | Should -Be 14402
        }

        It "Should accept Tagged_VLANs with database IDs larger than 4094" {
            $Result = New-NBDCIMInterface -Device 321 -Name "Test123" -Mode 'Tagged' -Tagged_VLANs 5000, 14402
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.tagged_vlans | Should -Be @(5000, 14402)
        }

        It "Should convert Mode 'Access' to API string 'access'" {
            $Result = New-NBDCIMInterface -Device 123 -Name "Test" -Mode 'Access'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mode | Should -Be 'access'
        }

        It "Should convert Mode 'Tagged' to API string 'tagged'" {
            $Result = New-NBDCIMInterface -Device 123 -Name "Test" -Mode 'Tagged'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mode | Should -Be 'tagged'
        }

        It "Should convert Mode 'Tagged All' to API string 'tagged-all'" {
            $Result = New-NBDCIMInterface -Device 123 -Name "Test" -Mode 'Tagged All'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mode | Should -Be 'tagged-all'
        }

        It "Should convert legacy numeric Mode '100' to 'access'" {
            $Result = New-NBDCIMInterface -Device 123 -Name "Test" -Mode '100'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mode | Should -Be 'access'
        }

        It "Should convert legacy numeric Mode '200' to 'tagged'" {
            $Result = New-NBDCIMInterface -Device 123 -Name "Test" -Mode '200'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mode | Should -Be 'tagged'
        }

        It "Should convert legacy numeric Mode '300' to 'tagged-all'" {
            $Result = New-NBDCIMInterface -Device 123 -Name "Test" -Mode '300'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mode | Should -Be 'tagged-all'
        }

        Context "New-NBDCIMInterface new parameters (#394)" {
            It "Should pass -Label in the request body" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Label 'port-01'
                ($Result.Body | ConvertFrom-Json).label | Should -Be 'port-01'
            }

            It "Should pass -Parent as the parent numeric ID" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0.100' -Type 'virtual' -Parent 42
                ($Result.Body | ConvertFrom-Json).parent | Should -Be 42
            }

            It "Should pass -Bridge as the bridge numeric ID" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'br0' -Type 'bridge' -Bridge 99
                ($Result.Body | ConvertFrom-Json).bridge | Should -Be 99
            }

            It "Should pass -Speed in Kbps" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Speed 1000000
                ($Result.Body | ConvertFrom-Json).speed | Should -Be 1000000
            }

            It "Should pass -Duplex with valid value 'full'" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Duplex 'full'
                ($Result.Body | ConvertFrom-Json).duplex | Should -Be 'full'
            }

            It "Should reject -Duplex with invalid value" {
                { New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Duplex 'invalid' } |
                    Should -Throw
            }

            It "Should pass -Mark_Connected as boolean true" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Mark_Connected $true
                ($Result.Body | ConvertFrom-Json).mark_connected | Should -Be $true
            }

            It "Should pass -WWN with valid 8-group FC format" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'fc0' -Type '16gfc-sfpp' -WWN 'aa:bb:cc:dd:ee:ff:00:11'
                ($Result.Body | ConvertFrom-Json).wwn | Should -Be 'aa:bb:cc:dd:ee:ff:00:11'
            }

            It "Should reject -WWN with invalid format" {
                { New-NBDCIMInterface -Device 1 -Name 'fc0' -Type '16gfc-sfpp' -WWN 'not-a-wwn' } |
                    Should -Throw
            }

            It "Should pass -VDCS as array of integer IDs" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -VDCS 10, 20, 30
                $body = $Result.Body | ConvertFrom-Json
                $body.vdcs | Should -Contain 10
                $body.vdcs | Should -Contain 20
                $body.vdcs | Should -Contain 30
            }

            It "Should pass -POE_Mode with valid value 'pse'" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Mode 'pse'
                ($Result.Body | ConvertFrom-Json).poe_mode | Should -Be 'pse'
            }

            It "Should reject -POE_Mode with invalid value" {
                { New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Mode 'invalid' } |
                    Should -Throw
            }

            It "Should pass -POE_Type with valid value 'type3-ieee802.3bt'" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Type 'type3-ieee802.3bt'
                ($Result.Body | ConvertFrom-Json).poe_type | Should -Be 'type3-ieee802.3bt'
            }

            It "Should reject -POE_Type with invalid value" {
                { New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -POE_Type 'wrong' } |
                    Should -Throw
            }

            It "Should pass -Vlan_Group as numeric ID" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Vlan_Group 77
                ($Result.Body | ConvertFrom-Json).vlan_group | Should -Be 77
            }

            It "Should pass -QinQ_SVLAN as numeric ID" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -QinQ_SVLAN 200
                ($Result.Body | ConvertFrom-Json).qinq_svlan | Should -Be 200
            }

            It "Should pass -VRF as numeric ID" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -VRF 5
                ($Result.Body | ConvertFrom-Json).vrf | Should -Be 5
            }

            It "Should pass -RF_Role with valid value 'ap'" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Role 'ap'
                ($Result.Body | ConvertFrom-Json).rf_role | Should -Be 'ap'
            }

            It "Should reject -RF_Role with invalid value" {
                { New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Role 'wrong' } |
                    Should -Throw
            }

            It "Should pass -RF_Channel as free-form string" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Channel '2.4g-1-2412-22'
                ($Result.Body | ConvertFrom-Json).rf_channel | Should -Be '2.4g-1-2412-22'
            }

            It "Should pass -RF_Channel_Frequency in MHz" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Channel_Frequency 5180
                ($Result.Body | ConvertFrom-Json).rf_channel_frequency | Should -Be 5180
            }

            It "Should pass -RF_Channel_Width in MHz" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -RF_Channel_Width 80
                ($Result.Body | ConvertFrom-Json).rf_channel_width | Should -Be 80
            }

            It "Should pass -TX_Power in dBm" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'wlan0' -Type 'ieee802.11ac' -TX_Power 20
                ($Result.Body | ConvertFrom-Json).tx_power | Should -Be 20
            }

            It "Should pass -Primary_MAC_Address as numeric ID" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Primary_MAC_Address 12345
                ($Result.Body | ConvertFrom-Json).primary_mac_address | Should -Be 12345
            }

            It "Should pass -Owner as numeric ID" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Owner 7
                ($Result.Body | ConvertFrom-Json).owner | Should -Be 7
            }

            It "Should pass -Changelog_Message as free-form string" {
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Changelog_Message 'Initial provisioning'
                ($Result.Body | ConvertFrom-Json).changelog_message | Should -Be 'Initial provisioning'
            }

            It "Should pass -Tags as array of objects" {
                $tag = [PSCustomObject]@{ slug = 'production'; color = '00ff00' }
                $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -Tags @($tag)
                $body = $Result.Body | ConvertFrom-Json
                $body.tags[0].slug | Should -Be 'production'
            }
        }
    }

    Context "New-NBDCIMInterface - Interface Type ValidateSet" {
        $newTypeTestCases = @(
            @{ Type = '10gbase-cu'; Label = '10GBASE-CU (new in 4.5.4)' }
            @{ Type = '40gbase-sr4-bd'; Label = '40GBASE-SR4 BiDi (new in 4.5.4)' }
            @{ Type = '1.6tbase-cr8'; Label = '1.6TBASE-CR8 (new in 4.5.6)' }
            @{ Type = '1.6tbase-dr8'; Label = '1.6TBASE-DR8 (new in 4.5.6)' }
            @{ Type = '1.6tbase-dr8-2'; Label = '1.6TBASE-DR8-2 (new in 4.5.6)' }
            @{ Type = '1.6tbase-kr8'; Label = '1.6TBASE-KR8 backplane (new in 4.5.6)' }
            @{ Type = '1.6tbase-x-osfp1600'; Label = 'OSFP1600 modular (new in 4.5.6)' }
            @{ Type = '1.6tbase-x-osfp1600-rhs'; Label = 'OSFP1600-RHS modular (new in 4.5.6)' }
            @{ Type = '1.6tbase-x-qsfpdd1600'; Label = 'QSFP-DD1600 modular (new in 4.5.6)' }
            @{ Type = '2.5gbase-x-sfp'; Label = '2.5GBASE-X SFP modular (new in 4.5.6)' }
            @{ Type = '100base-fx'; Label = '100BASE-FX' }
            @{ Type = '1000base-sx'; Label = '1000BASE-SX' }
            @{ Type = '1000base-lx'; Label = '1000BASE-LX' }
            @{ Type = '25gbase-sr'; Label = '25GBASE-SR' }
            @{ Type = '40gbase-sr4'; Label = '40GBASE-SR4' }
            @{ Type = '50gbase-sr'; Label = '50GBASE-SR' }
            @{ Type = '100gbase-sr4'; Label = '100GBASE-SR4' }
            @{ Type = '200gbase-sr4'; Label = '200GBASE-SR4' }
            @{ Type = '400gbase-sr8'; Label = '400GBASE-SR8' }
            @{ Type = '800gbase-sr8'; Label = '800GBASE-SR8' }
            @{ Type = '100gbase-x-qsfpdd'; Label = '100GBASE-X-QSFPDD' }
            @{ Type = '800gbase-x-osfp'; Label = '800GBASE-X-OSFP' }
            @{ Type = 'ieee802.11be'; Label = 'Wi-Fi 7' }
            @{ Type = '5g'; Label = '5G Cellular' }
            @{ Type = '50g-pon'; Label = '50G-PON' }
            @{ Type = '64gfc-sfpp'; Label = '64GFC SFP+' }
            @{ Type = 'moca'; Label = 'MoCA' }
            @{ Type = 'cisco-stackwise-1t'; Label = 'Cisco StackWise-1T' }
        )

        It 'Should accept interface type <Label>' -TestCases $newTypeTestCases {
            param($Type, $Label)
            $Result = New-NBDCIMInterface -Device 1 -Name "test-$Type" -Type $Type
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.type | Should -Be $Type
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

        It "Should accept new 4.5.4 interface type '10gbase-cu'" {
            $Result = Set-NBDCIMInterface -Id 123 -Type '10gbase-cu' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.type | Should -Be '10gbase-cu'
        }

        It "Should accept new 4.5.4 interface type '40gbase-sr4-bd'" {
            $Result = Set-NBDCIMInterface -Id 123 -Type '40gbase-sr4-bd' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.type | Should -Be '40gbase-sr4-bd'
        }

        It "Should accept previously missing type '800gbase-sr8'" {
            $Result = Set-NBDCIMInterface -Id 123 -Type '800gbase-sr8' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.type | Should -Be '800gbase-sr8'
        }

        It "Should accept new 4.5.6 1.6TE fixed type '1.6tbase-cr8'" {
            $Result = Set-NBDCIMInterface -Id 123 -Type '1.6tbase-cr8' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.type | Should -Be '1.6tbase-cr8'
        }

        It "Should accept new 4.5.6 1.6TE modular type '1.6tbase-x-osfp1600'" {
            $Result = Set-NBDCIMInterface -Id 123 -Type '1.6tbase-x-osfp1600' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.type | Should -Be '1.6tbase-x-osfp1600'
        }

        It "Should accept new 4.5.6 2.5GE modular type '2.5gbase-x-sfp'" {
            $Result = Set-NBDCIMInterface -Id 123 -Type '2.5gbase-x-sfp' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.type | Should -Be '2.5gbase-x-sfp'
        }

        It "Should convert Mode 'Access' to API string 'access'" {
            $Result = Set-NBDCIMInterface -Id 123 -Mode 'Access' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mode | Should -Be 'access'
        }

        It "Should convert Mode 'Tagged All' to API string 'tagged-all'" {
            $Result = Set-NBDCIMInterface -Id 123 -Mode 'Tagged All' -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mode | Should -Be 'tagged-all'
        }

        It "Should accept VLAN database IDs larger than 4094" {
            $Result = Set-NBDCIMInterface -Id 123 -Untagged_VLAN 14402 -Force
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.untagged_vlan | Should -Be 14402
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
