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

Describe "Setup tests" -Tag 'Core', 'Setup' {
    It "Throws an error for an empty hostname" {
        { Get-NBHostname } | Should -Throw
    }

    It "Sets the hostname" {
        Set-NBHostName -HostName 'netbox.domain.com' | Should -Be 'netbox.domain.com'
    }

    It "Gets the hostname from the variable" {
        Get-NBHostName | Should -Be 'netbox.domain.com'
    }

    It "Throws an error for empty credentials" {
        { Get-NBCredential } | Should -Throw
    }

    Context "Plain text credentials" {
        It "Sets the credentials using plain text" {
            Set-NBCredential -Token (ConvertTo-SecureString -String "faketoken" -Force -AsPlainText) | Should -BeOfType [pscredential]
        }

        It "Checks the set credentials" {
            Set-NBCredential -Token (ConvertTo-SecureString -String "faketoken" -Force -AsPlainText)
            (Get-NBCredential).GetNetworkCredential().Password | Should -BeExactly "faketoken"
        }
    }

    Context "Credentials object" {
        It "Sets the credentials using [pscredential]" {
            $Creds = [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            Set-NBCredential -Credential $Creds | Should -BeOfType [pscredential]
        }

        It "Checks the set credentials" {
            (Get-NBCredential).GetNetworkCredential().Password | Should -BeExactly 'faketoken'
        }
    }

    Context "Token v2 Bearer Authentication" {
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
            Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should use Token auth header for v1 legacy tokens" {
            $v1Token = '0123456789abcdef0123456789abcdef01234567'
            Set-NBCredential -Token (ConvertTo-SecureString -String $v1Token -AsPlainText -Force)

            $Result = Get-NBDCIMSite
            $Result.Headers.Authorization | Should -Be "Token $v1Token"
        }

        It "Should use Bearer auth header for v2 nbt_ tokens" {
            $v2Token = 'nbt_abc123def456.ghijklmnopqrstuvwxyz1234567890'
            Set-NBCredential -Token (ConvertTo-SecureString -String $v2Token -AsPlainText -Force)

            $Result = Get-NBDCIMSite
            $Result.Headers.Authorization | Should -Be "Bearer $v2Token"
        }

        It "Should use Token auth for tokens not starting with nbt_" {
            $legacyToken = 'mylegacytoken12345'
            Set-NBCredential -Token (ConvertTo-SecureString -String $legacyToken -AsPlainText -Force)

            $Result = Get-NBDCIMSite
            $Result.Headers.Authorization | Should -Be "Token $legacyToken"
        }
    }
}
