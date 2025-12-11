[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

Import-Module Pester
Remove-Module NetboxPSv4 -Force -ErrorAction SilentlyContinue

$ModulePath = Join-Path $PSScriptRoot ".." "NetboxPSv4" "NetboxPSv4.psd1"

if (Test-Path $ModulePath) {
    Import-Module $ModulePath -ErrorAction Stop
}

Describe "Wireless Module Tests" -Tag 'Wireless' {
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
        Context "Wireless LANs" {
            It "Should get wireless LANs" {
                $Result = Get-NBWirelessLAN

                Should -InvokeVerifiable
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/'
            }

            It "Should create a wireless LAN" {
                $Result = New-NBWirelessLAN -SSID "TestWiFi"

                Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -Scope 'It'
                $Result.Method | Should -Be 'POST'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lans/'
            }
        }

        Context "Wireless LAN Groups" {
            It "Should get wireless LAN groups" {
                $Result = Get-NBWirelessLANGroup

                Should -InvokeVerifiable
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-lan-groups/'
            }
        }

        Context "Wireless Links" {
            It "Should get wireless links" {
                $Result = Get-NBWirelessLink

                Should -InvokeVerifiable
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be 'https://netbox.domain.com/api/wireless/wireless-links/'
            }
        }
    }
}
