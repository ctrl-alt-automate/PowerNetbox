<#
.SYNOPSIS
    The verbose stream must never contain the secrets of a request body.

.DESCRIPTION
    InvokeNetboxRequest writes "BODY: <json>" to the verbose stream. Verbose output ends up in
    transcripts, CI logs and bug reports, so passwords, pre-shared keys, webhook secrets and
    tokens have to be masked there - while the request that goes to NetBox keeps the real value.

    These tests mock at the Invoke-RestMethod level on purpose: mocking InvokeNetboxRequest
    would skip the very code under test.
#>

param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    function ConvertTo-TestSecureString {
        param([string]$Text)
        ConvertTo-SecureString $Text -AsPlainText -Force
    }

    # Everything a cmdlet wrote to the verbose stream, as one string.
    function Get-VerboseText {
        param([object[]]$Output)
        ($Output | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } |
            ForEach-Object { $_.Message }) -join "`n"
    }
}

Describe "Verbose request-body redaction" -Tag 'Security', 'Redaction' {

    BeforeAll {
        InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
            $script:NetboxConfig.Hostname = 'netbox.test.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            [PSCredential]::new('api', (ConvertTo-SecureString 'test-token' -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { 'netbox.test.com' }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { @{} }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { 30 }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith { [PSCustomObject]@{ id = 1 } }
    }

    Context "Cmdlets that send a secret" {

        It "<Cmdlet> masks <Field> in the verbose stream and still sends it to NetBox" -TestCases @(
            @{ Cmdlet = 'New-NBUser';         Field = 'password';      Secret = 'dummy-password-0001'; Splat = @{ Username = 'alice' };                         SecretParam = 'Password' }
            @{ Cmdlet = 'Set-NBUser';         Field = 'password';      Secret = 'dummy-password-0001'; Splat = @{ Id = 7 };                                     SecretParam = 'Password' }
            @{ Cmdlet = 'New-NBWirelessLAN';  Field = 'auth_psk';      Secret = 'fake-secret-psk-0002';    Splat = @{ SSID = 'corp' };                              SecretParam = 'Auth_PSK' }
            @{ Cmdlet = 'New-NBVPNIKEPolicy'; Field = 'preshared_key'; Secret = 'fake-key-ike-0003';     Splat = @{ Name = 'ike-pol' };                           SecretParam = 'Preshared_Key' }
            @{ Cmdlet = 'New-NBWebhook';      Field = 'secret';        Secret = 'dummy-secret-hmac-0004';       Splat = @{ Name = 'hook'; Payload_Url = 'https://x.test' }; SecretParam = 'Secret' }
        ) {
            param($Cmdlet, $Field, $Secret, $Splat, $SecretParam)

            $Splat[$SecretParam] = ConvertTo-TestSecureString $Secret
            $out = & $Cmdlet @Splat -Confirm:$false -Verbose 4>&1
            $verbose = Get-VerboseText $out

            $verbose | Should -Match 'BODY: ' -Because 'the body line is the thing under test'
            $verbose | Should -Not -Match ([regex]::Escape($Secret)) -Because "the $Field value must never reach the verbose stream"
            $verbose | Should -Match ('"{0}":"\*\*\*REDACTED\*\*\*"' -f $Field)

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -Scope It -ParameterFilter {
                $Body -match ('"{0}":"{1}"' -f $Field, [regex]::Escape($Secret))
            } -Because 'redaction applies to the log line only; NetBox must receive the real value'
        }

        It "Logs the entries of the body, not the .NET members of the hashtable" {
            $out = New-NBWirelessLAN -SSID 'corp' -Auth_PSK (ConvertTo-TestSecureString 'fake-secret-psk-0002') -Description 'lobby' -Confirm:$false -Verbose 4>&1
            $verbose = Get-VerboseText $out

            # Non-sensitive fields stay readable - that is what the line is for.
            $verbose | Should -Match '"ssid":"corp"'
            $verbose | Should -Match '"description":"lobby"'
            # $hashtable.PSObject.Properties yields these instead of the entries (the original bug).
            $verbose | Should -Not -Match 'SyncRoot|IsSynchronized|IsFixedSize|IsReadOnly'
        }
    }

    Context "Nested values" {

        It "Masks secrets inside a nested hashtable (data source parameters)" {
            $out = New-NBDataSource -Name 'cfg' -Type 'git' -Source_Url 'https://git.test/repo.git' -Parameters @{
                username = 'svc-netbox'
                password = 'dummy-password-git-0005'
                branch   = 'main'
            } -Confirm:$false -Verbose 4>&1
            $verbose = Get-VerboseText $out

            $verbose | Should -Not -Match 'dummy-password-git-0005'
            $verbose | Should -Match '"password":"\*\*\*REDACTED\*\*\*"'
            $verbose | Should -Match '"username":"svc-netbox"'
            $verbose | Should -Match '"branch":"main"'

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -Scope It -ParameterFilter {
                $Body -match '"password":"dummy-password-git-0005"'
            }
        }

        It "Masks secrets inside custom fields" {
            $out = New-NBIPAMAddress -Address '10.0.0.1/24' -Custom_Fields @{ snmp_secret = 'community-xyz'; floor = 3 } -Confirm:$false -Verbose 4>&1
            $verbose = Get-VerboseText $out

            $verbose | Should -Not -Match 'community-xyz'
            $verbose | Should -Match '"snmp_secret":"\*\*\*REDACTED\*\*\*"'
            $verbose | Should -Match '"floor":3'
        }

        It "Does not warn about truncated JSON for a nested body (<Name>)" -TestCases @(
            @{ Name = 'without -Verbose'; Verbose = $false }
            @{ Name = 'with -Verbose';    Verbose = $true }
        ) {
            param($Name, $Verbose)

            $a = @(@{ object_type = 'dcim.interface'; object_id = 1 })
            $b = @(@{ object_type = 'dcim.interface'; object_id = 2 })
            $out = New-NBDCIMCable -A_Terminations $a -B_Terminations $b -Confirm:$false -Verbose:$Verbose 3>&1 4>&1
            $warnings = @($out | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })

            $warnings | Where-Object { $_.Message -match 'truncated' } | Should -BeNullOrEmpty
        }
    }

    Context "ConvertToNBRedactedBody (helper)" {

        It "Masks every sensitive name pattern at the top level" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $body = @{
                    name          = 'visible'
                    password      = 'p'
                    secret        = 's'
                    auth_psk      = 'k1'
                    preshared_key = 'k2'
                    api_token     = 't'
                }
                $json = ConvertToNBRedactedBody -Body $body | ConvertTo-Json -Compress -Depth 10

                $json | Should -Match '"name":"visible"'
                foreach ($field in 'password', 'secret', 'auth_psk', 'preshared_key', 'api_token') {
                    $json | Should -Match ('"{0}":"\*\*\*REDACTED\*\*\*"' -f $field)
                }
            }
        }

        It "Recurses into dictionaries and arrays of dictionaries" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $body = @{
                    parameters = @{ password = 'deep-1'; region = 'eu' }
                    items      = @(
                        @{ token = 'deep-2'; n = 1 }
                        'plain-string'
                    )
                }
                $json = ConvertToNBRedactedBody -Body $body | ConvertTo-Json -Compress -Depth 10

                $json | Should -Not -Match 'deep-1|deep-2'
                $json | Should -Match '"region":"eu"'
                $json | Should -Match '"n":1'
                $json | Should -Match 'plain-string'
            }
        }

        It "Handles a PSCustomObject body" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $body = [PSCustomObject]@{ name = 'visible'; password = 'obj-secret'; nested = [PSCustomObject]@{ secret = 'obj-deep'; ok = 'yes' } }
                $json = ConvertToNBRedactedBody -Body $body | ConvertTo-Json -Compress -Depth 10

                $json | Should -Not -Match 'obj-secret|obj-deep'
                $json | Should -Match '"name":"visible"'
                $json | Should -Match '"ok":"yes"'
            }
        }

        It "Leaves the original body untouched" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $body = @{ password = 'keep-me'; parameters = @{ secret = 'keep-me-too' } }
                $null = ConvertToNBRedactedBody -Body $body

                $body.password | Should -Be 'keep-me'
                $body.parameters.secret | Should -Be 'keep-me-too'
            }
        }

        It "Keeps null, empty and scalar values intact" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $body = @{ description = ''; tenant = $null; vid = 100; enabled = $true; tags = @() }
                $result = ConvertToNBRedactedBody -Body $body

                $result['description'] | Should -Be ''
                $result['tenant'] | Should -BeNullOrEmpty
                $result['vid'] | Should -Be 100
                $result['enabled'] | Should -BeTrue
                @($result['tags']).Count | Should -Be 0
            }
        }
    }
}
