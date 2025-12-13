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

Describe "VPN Module Tests" -Tag 'VPN' {
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

    Context "Tunnels" {
        It "Should get tunnels" {
            $Result = Get-NBVPNTunnel
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/'
        }

        It "Should create a tunnel" {
            $Result = New-NBVPNTunnel -Name "Test-Tunnel" -Status "active" -Encapsulation "ipsec-tunnel"
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/'
        }
    }

    Context "L2VPN" {
        It "Should get L2VPNs" {
            $Result = Get-NBVPNL2VPN
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/'
        }

        It "Should create an L2VPN" {
            $Result = New-NBVPNL2VPN -Name "Test-L2VPN" -Slug "test-l2vpn" -Type "vxlan"
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/'
        }
    }

    Context "IKE Policies" {
        It "Should get IKE policies" {
            $Result = Get-NBVPNIKEPolicy
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-policies/'
        }
    }

    Context "IPSec Policies" {
        It "Should get IPSec policies" {
            $Result = Get-NBVPNIPSecPolicy
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-policies/'
        }
    }
}
