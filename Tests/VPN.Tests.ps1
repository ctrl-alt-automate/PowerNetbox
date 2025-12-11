[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

Import-Module Pester
Remove-Module NetboxPSv4 -Force -ErrorAction SilentlyContinue

$ModulePath = Join-Path $PSScriptRoot ".." "NetboxPSv4" "NetboxPSv4.psd1"

if (Test-Path $ModulePath) {
    Import-Module $ModulePath -ErrorAction Stop
}

Describe "VPN Module Tests" -Tag 'VPN' {
    Mock -CommandName 'CheckNetboxIsConnected' -Verifiable -ModuleName 'NetboxPSv4' -MockWith {
        return $true
    }

    Mock -CommandName 'Invoke-RestMethod' -Verifiable -ModuleName 'NetboxPSv4' -MockWith {
        return [ordered]@{
            'Method'      = $Method
            'Uri'         = $Uri
            'Headers'     = $Headers
            'Timeout'     = $Timeout
            'ContentType' = $ContentType
            'Body'        = $Body
        }
    }

    Mock -CommandName 'Get-NBCredential' -Verifiable -ModuleName 'NetboxPSv4' -MockWith {
        return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
    }

    Mock -CommandName 'Get-NBHostname' -Verifiable -ModuleName 'NetboxPSv4' -MockWith {
        return 'netbox.domain.com'
    }

    InModuleScope -ModuleName 'NetboxPSv4' -ScriptBlock {
        Context "Tunnels" {
            It "Should get tunnels" {
                $Result = Get-NBVPNTunnel

                Should -InvokeVerifiable
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/'
            }

            It "Should create a tunnel" {
                $Result = New-NBVPNTunnel -Name "Test-Tunnel" -Status "active" -Encapsulation "ipsec-tunnel"

                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It'
                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/'
            }
        }

        Context "L2VPN" {
            It "Should get L2VPNs" {
                $Result = Get-NBVPNL2VPN

                Should -InvokeVerifiable
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/'
            }

            It "Should create an L2VPN" {
                $Result = New-NBVPNL2VPN -Name "Test-L2VPN" -Slug "test-l2vpn" -Type "vxlan"

                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It'
                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/'
            }
        }

        Context "IKE Policies" {
            It "Should get IKE policies" {
                $Result = Get-NBVPNIKEPolicy

                Should -InvokeVerifiable
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-policies/'
            }
        }

        Context "IPSec Policies" {
            It "Should get IPSec policies" {
                $Result = Get-NBVPNIPSecPolicy

                Should -InvokeVerifiable
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-policies/'
            }
        }
    }
}
