
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
)
Import-Module Pester
Remove-Module NetboxPS -Force -ErrorAction SilentlyContinue

 = Join-Path  ".." "NetboxPS" "NetboxPS.psd1"

if (Test-Path $ModulePath) {
    Import-Module $ModulePath -ErrorAction Stop
}

Describe "Setup tests" -Tag 'Core', 'Setup' -Fixture {
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
        $Creds = [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))

        It "Sets the credentials using [pscredential]" {
            Set-NBCredential -Credential $Creds | Should -BeOfType [pscredential]
        }

        It "Checks the set credentials" {
            (Get-NBCredential).GetNetworkCredential().Password | Should -BeExactly 'faketoken'
        }
    }

    <#
    Context "Connecting to the API" {
        Mock Get-NBCircuitsChoices {
            return $true
        } -ModuleName NetboxPS -Verifiable

        $Creds = [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))

        It "Connects using supplied hostname and obtained credentials" {
            #$null = Set-NBCredentials -Credentials $Creds
            Connect-NBAPI -Hostname "fake.org" | Should -Be $true
        }

        It "Connects using supplied hostname and credentials" {
            Connect-NBAPI -Hostname 'fake.org' -Credentials $Creds | Should -Be $true
        }



        Assert-MockCalled -CommandName Get-NBCircuitsChoices -ModuleName NetboxPS
    }
    #>
}








