<#
.SYNOPSIS
    Unit tests for VPN module functions.

.DESCRIPTION
    Tests for all VPN endpoints: Tunnels, TunnelGroups, TunnelTerminations,
    L2VPN, L2VPNTerminations, IKEPolicy, IKEProposal, IPSecPolicy, IPSecProfile, IPSecProposal.
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

Describe "VPN Module Tests" -Tag 'VPN' {
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

    #region Tunnel Tests
    Context "Get-NBVPNTunnel" {
        It "Should request tunnels" {
            $Result = Get-NBVPNTunnel
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/'
        }

        It "Should request a tunnel by ID" {
            $Result = Get-NBVPNTunnel -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/5/'
        }

        It "Should request tunnels by name" {
            $Result = Get-NBVPNTunnel -Name 'test-tunnel'
            $Result.Uri | Should -Match 'name=test-tunnel'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBVPNTunnel -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBVPNTunnel" {
        It "Should create a tunnel" {
            $Result = New-NBVPNTunnel -Name "test-tunnel" -Status "active" -Encapsulation "ipsec-tunnel" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'test-tunnel'
            $bodyObj.status | Should -Be 'active'
        }

        It "Should support -WhatIf" {
            $Result = New-NBVPNTunnel -Name "whatif-tunnel" -Status "active" -Encapsulation "gre" -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }

    Context "Set-NBVPNTunnel" {
        It "Should update a tunnel" {
            $Result = Set-NBVPNTunnel -Id 1 -Name 'updated-tunnel' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'updated-tunnel'
        }
    }

    Context "Remove-NBVPNTunnel" {
        It "Should delete a tunnel" {
            $Result = Remove-NBVPNTunnel -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnels/1/'
        }
    }
    #endregion

    #region TunnelGroup Tests
    Context "Get-NBVPNTunnelGroup" {
        It "Should request tunnel groups" {
            $Result = Get-NBVPNTunnelGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-groups/'
        }

        It "Should request a tunnel group by ID" {
            $Result = Get-NBVPNTunnelGroup -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-groups/5/'
        }
    }

    Context "New-NBVPNTunnelGroup" {
        It "Should create a tunnel group" {
            $Result = New-NBVPNTunnelGroup -Name "test-group" -Slug "test-group" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-groups/'
        }
    }

    Context "Set-NBVPNTunnelGroup" {
        It "Should update a tunnel group" {
            $Result = Set-NBVPNTunnelGroup -Id 1 -Name 'updated-group' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-groups/1/'
        }
    }

    Context "Remove-NBVPNTunnelGroup" {
        It "Should delete a tunnel group" {
            $Result = Remove-NBVPNTunnelGroup -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-groups/1/'
        }
    }
    #endregion

    #region TunnelTermination Tests
    Context "Get-NBVPNTunnelTermination" {
        It "Should request tunnel terminations" {
            $Result = Get-NBVPNTunnelTermination
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-terminations/'
        }

        It "Should request a tunnel termination by ID" {
            $Result = Get-NBVPNTunnelTermination -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-terminations/5/'
        }
    }

    Context "New-NBVPNTunnelTermination" {
        It "Should create a tunnel termination" {
            $Result = New-NBVPNTunnelTermination -Tunnel 1 -Role "hub" -Termination_Type "dcim.interface" -Termination_Id 10 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-terminations/'
        }
    }

    Context "Set-NBVPNTunnelTermination" {
        It "Should update a tunnel termination" {
            $Result = Set-NBVPNTunnelTermination -Id 1 -Role 'spoke' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-terminations/1/'
        }
    }

    Context "Remove-NBVPNTunnelTermination" {
        It "Should delete a tunnel termination" {
            $Result = Remove-NBVPNTunnelTermination -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/tunnel-terminations/1/'
        }
    }
    #endregion

    #region L2VPN Tests
    Context "Get-NBVPNL2VPN" {
        It "Should request L2VPNs" {
            $Result = Get-NBVPNL2VPN
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/'
        }

        It "Should request an L2VPN by ID" {
            $Result = Get-NBVPNL2VPN -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/5/'
        }

        It "Should request L2VPNs by type" {
            $Result = Get-NBVPNL2VPN -Type 'vxlan'
            $Result.Uri | Should -Match 'type=vxlan'
        }
    }

    Context "New-NBVPNL2VPN" {
        It "Should create an L2VPN" {
            $Result = New-NBVPNL2VPN -Name "test-l2vpn" -Slug "test-l2vpn" -Type "vxlan" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'test-l2vpn'
            $bodyObj.type | Should -Be 'vxlan'
        }
    }

    Context "Set-NBVPNL2VPN" {
        It "Should update an L2VPN" {
            $Result = Set-NBVPNL2VPN -Id 1 -Name 'updated-l2vpn' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/1/'
        }
    }

    Context "Remove-NBVPNL2VPN" {
        It "Should delete an L2VPN" {
            $Result = Remove-NBVPNL2VPN -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpns/1/'
        }
    }
    #endregion

    #region L2VPNTermination Tests
    Context "Get-NBVPNL2VPNTermination" {
        It "Should request L2VPN terminations" {
            $Result = Get-NBVPNL2VPNTermination
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpn-terminations/'
        }

        It "Should request an L2VPN termination by ID" {
            $Result = Get-NBVPNL2VPNTermination -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpn-terminations/5/'
        }
    }

    Context "New-NBVPNL2VPNTermination" {
        It "Should create an L2VPN termination" {
            $Result = New-NBVPNL2VPNTermination -L2VPN 1 -Assigned_Object_Type "dcim.interface" -Assigned_Object_Id 10 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpn-terminations/'
        }
    }

    Context "Set-NBVPNL2VPNTermination" {
        It "Should update an L2VPN termination" {
            $Result = Set-NBVPNL2VPNTermination -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpn-terminations/1/'
        }
    }

    Context "Remove-NBVPNL2VPNTermination" {
        It "Should delete an L2VPN termination" {
            $Result = Remove-NBVPNL2VPNTermination -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/l2vpn-terminations/1/'
        }
    }
    #endregion

    #region IKEPolicy Tests
    Context "Get-NBVPNIKEPolicy" {
        It "Should request IKE policies" {
            $Result = Get-NBVPNIKEPolicy
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-policies/'
        }

        It "Should request an IKE policy by ID" {
            $Result = Get-NBVPNIKEPolicy -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-policies/5/'
        }
    }

    Context "New-NBVPNIKEPolicy" {
        It "Should create an IKE policy" {
            $Result = New-NBVPNIKEPolicy -Name "test-ike-policy" -Version 2 -Mode "main" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-policies/'
        }
    }

    Context "Set-NBVPNIKEPolicy" {
        It "Should update an IKE policy" {
            $Result = Set-NBVPNIKEPolicy -Id 1 -Name 'updated-policy' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-policies/1/'
        }
    }

    Context "Remove-NBVPNIKEPolicy" {
        It "Should delete an IKE policy" {
            $Result = Remove-NBVPNIKEPolicy -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-policies/1/'
        }
    }
    #endregion

    #region IKEProposal Tests
    Context "Get-NBVPNIKEProposal" {
        It "Should request IKE proposals" {
            $Result = Get-NBVPNIKEProposal
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-proposals/'
        }

        It "Should request an IKE proposal by ID" {
            $Result = Get-NBVPNIKEProposal -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-proposals/5/'
        }
    }

    Context "New-NBVPNIKEProposal" {
        It "Should create an IKE proposal" {
            $Result = New-NBVPNIKEProposal -Name "test-proposal" -Authentication_Method "preshared-keys" -Encryption_Algorithm "aes-128-cbc" -Authentication_Algorithm "hmac-sha256" -Group 14 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-proposals/'
        }
    }

    Context "Set-NBVPNIKEProposal" {
        It "Should update an IKE proposal" {
            $Result = Set-NBVPNIKEProposal -Id 1 -Name 'updated-proposal' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-proposals/1/'
        }
    }

    Context "Remove-NBVPNIKEProposal" {
        It "Should delete an IKE proposal" {
            $Result = Remove-NBVPNIKEProposal -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ike-proposals/1/'
        }
    }
    #endregion

    #region IPSecPolicy Tests
    Context "Get-NBVPNIPSecPolicy" {
        It "Should request IPSec policies" {
            $Result = Get-NBVPNIPSecPolicy
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-policies/'
        }

        It "Should request an IPSec policy by ID" {
            $Result = Get-NBVPNIPSecPolicy -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-policies/5/'
        }
    }

    Context "New-NBVPNIPSecPolicy" {
        It "Should create an IPSec policy" {
            $Result = New-NBVPNIPSecPolicy -Name "test-ipsec-policy" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-policies/'
        }
    }

    Context "Set-NBVPNIPSecPolicy" {
        It "Should update an IPSec policy" {
            $Result = Set-NBVPNIPSecPolicy -Id 1 -Name 'updated-policy' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-policies/1/'
        }
    }

    Context "Remove-NBVPNIPSecPolicy" {
        It "Should delete an IPSec policy" {
            $Result = Remove-NBVPNIPSecPolicy -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-policies/1/'
        }
    }
    #endregion

    #region IPSecProfile Tests
    Context "Get-NBVPNIPSecProfile" {
        It "Should request IPSec profiles" {
            $Result = Get-NBVPNIPSecProfile
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-profiles/'
        }

        It "Should request an IPSec profile by ID" {
            $Result = Get-NBVPNIPSecProfile -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-profiles/5/'
        }
    }

    Context "New-NBVPNIPSecProfile" {
        It "Should create an IPSec profile" {
            $Result = New-NBVPNIPSecProfile -Name "test-profile" -Mode "esp" -IKE_Policy 1 -IPSec_Policy 1 -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-profiles/'
        }
    }

    Context "Set-NBVPNIPSecProfile" {
        It "Should update an IPSec profile" {
            $Result = Set-NBVPNIPSecProfile -Id 1 -Name 'updated-profile' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-profiles/1/'
        }
    }

    Context "Remove-NBVPNIPSecProfile" {
        It "Should delete an IPSec profile" {
            $Result = Remove-NBVPNIPSecProfile -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-profiles/1/'
        }
    }
    #endregion

    #region IPSecProposal Tests
    Context "Get-NBVPNIPSecProposal" {
        It "Should request IPSec proposals" {
            $Result = Get-NBVPNIPSecProposal
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-proposals/'
        }

        It "Should request an IPSec proposal by ID" {
            $Result = Get-NBVPNIPSecProposal -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-proposals/5/'
        }
    }

    Context "New-NBVPNIPSecProposal" {
        It "Should create an IPSec proposal" {
            $Result = New-NBVPNIPSecProposal -Name "test-proposal" -Encryption_Algorithm "aes-128-cbc" -Authentication_Algorithm "hmac-sha256" -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-proposals/'
        }
    }

    Context "Set-NBVPNIPSecProposal" {
        It "Should update an IPSec proposal" {
            $Result = Set-NBVPNIPSecProposal -Id 1 -Name 'updated-proposal' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-proposals/1/'
        }
    }

    Context "Remove-NBVPNIPSecProposal" {
        It "Should delete an IPSec proposal" {
            $Result = Remove-NBVPNIPSecProposal -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/vpn/ipsec-proposals/1/'
        }
    }
    #endregion

    #region -All/-PageSize Passthrough Tests
    Context "VPN Get- Functions -All/-PageSize passthrough" {
        It "Should pass -All switch to InvokeNetboxRequest for Get-NBVPNTunnel" {
            Get-NBVPNTunnel -All
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $All -eq $true
            }
        }

        It "Should pass -PageSize to InvokeNetboxRequest for Get-NBVPNTunnel" {
            Get-NBVPNTunnel -All -PageSize 500
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $PageSize -eq 500
            }
        }

        It "Should pass -All switch to InvokeNetboxRequest for Get-NBVPNIKEPolicy" {
            Get-NBVPNIKEPolicy -All
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $All -eq $true
            }
        }

        It "Should pass -PageSize to InvokeNetboxRequest for Get-NBVPNIKEPolicy" {
            Get-NBVPNIKEPolicy -All -PageSize 500
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $PageSize -eq 500
            }
        }
    }
    #endregion

    #region Pagination Parameter Tests
    Context "VPN Get- Functions Pagination Support" {
        It "Get-NBVPNIKEPolicy should have -All parameter" {
            $cmd = Get-Command Get-NBVPNIKEPolicy
            $cmd.Parameters.Keys | Should -Contain 'All'
            $cmd.Parameters['All'].ParameterType.Name | Should -Be 'SwitchParameter'
        }

        It "Get-NBVPNIKEPolicy should have -PageSize parameter" {
            $cmd = Get-Command Get-NBVPNIKEPolicy
            $cmd.Parameters.Keys | Should -Contain 'PageSize'
            $cmd.Parameters['PageSize'].ParameterType.Name | Should -Be 'Int32'
        }

        It "Get-NBVPNIKEProposal should have -All parameter" {
            $cmd = Get-Command Get-NBVPNIKEProposal
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBVPNIPSecPolicy should have -All parameter" {
            $cmd = Get-Command Get-NBVPNIPSecPolicy
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBVPNIPSecProfile should have -All parameter" {
            $cmd = Get-Command Get-NBVPNIPSecProfile
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBVPNIPSecProposal should have -All parameter" {
            $cmd = Get-Command Get-NBVPNIPSecProposal
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBVPNL2VPN should have -All parameter" {
            $cmd = Get-Command Get-NBVPNL2VPN
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBVPNL2VPNTermination should have -All parameter" {
            $cmd = Get-Command Get-NBVPNL2VPNTermination
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBVPNTunnelGroup should have -All parameter" {
            $cmd = Get-Command Get-NBVPNTunnelGroup
            $cmd.Parameters.Keys | Should -Contain 'All'
        }

        It "Get-NBVPNTunnelTermination should have -All parameter" {
            $cmd = Get-Command Get-NBVPNTunnelTermination
            $cmd.Parameters.Keys | Should -Contain 'All'
        }
    }
    #endregion
}
