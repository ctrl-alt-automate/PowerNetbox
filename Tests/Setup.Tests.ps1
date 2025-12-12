[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path $PSScriptRoot ".." "PowerNetbox" "PowerNetbox.psd1"
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
}
