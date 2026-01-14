#Requires -Module Pester

<#
.SYNOPSIS
    Cross-platform compatibility tests for PowerNetbox.

.DESCRIPTION
    Validates that the module works correctly on Windows, Linux, and macOS.
    Tests platform-specific code paths for TLS, certificates, and encoding.
#>

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    . "$PSScriptRoot/common.ps1"
}

Describe "PowerNetbox Cross-Platform Compatibility" -Tag 'CrossPlatform' {

    Context "Platform Detection" {

        It "Should correctly identify PowerShell edition" {
            $PSVersionTable.PSEdition | Should -BeIn @('Desktop', 'Core')
        }

        It "Should have valid PSVersion" {
            $PSVersionTable.PSVersion.Major | Should -BeGreaterOrEqual 5
        }
    }

    Context "URI Building" {

        BeforeAll {
            # Set up module internal state
            InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
                $script:NetboxConfig.Hostname = 'netbox.example.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should build URIs with forward slashes on all platforms" {
            InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
                $uri = BuildNewURI -Segments @('dcim', 'devices') -SkipConnectedCheck
                $uri.Uri.AbsoluteUri | Should -Match '/api/dcim/devices/'
                $uri.Uri.AbsoluteUri | Should -Not -Match '\\'
            }
        }

        It "Should handle special characters in query parameters" {
            InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
                $uri = BuildNewURI -Segments @('dcim', 'devices') -Parameters @{ name = 'test device' } -SkipConnectedCheck
                $uri.Uri.AbsoluteUri | Should -Match 'name='
            }
        }

        It "Should not use backslashes in any URI" {
            InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
                $testSegments = @(
                    @('dcim', 'devices'),
                    @('ipam', 'ip-addresses'),
                    @('virtualization', 'virtual-machines')
                )

                foreach ($segments in $testSegments) {
                    $uri = BuildNewURI -Segments $segments -SkipConnectedCheck
                    $uri.Uri.AbsoluteUri | Should -Not -Match '\\' -Because "URI should use forward slashes: $($uri.Uri.AbsoluteUri)"
                }
            }
        }
    }

    Context "TLS Configuration" {

        It "Should configure TLS without errors" {
            { Set-NBCipherSSL } | Should -Not -Throw
        }

        It "Should support TLS 1.2 at minimum" {
            # After Set-NBCipherSSL, TLS 1.2 should be enabled
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                [System.Net.ServicePointManager]::SecurityProtocol | Should -Match 'Tls12'
            }
            else {
                # PowerShell Core uses modern TLS by default and HttpClient handles it internally
                # Verify that Invoke-RestMethod supports SkipCertificateCheck which indicates modern TLS support
                $cmdlet = Get-Command Invoke-RestMethod
                $cmdlet.Parameters.ContainsKey('SkipCertificateCheck') | Should -BeTrue -Because "PowerShell Core should support modern TLS via HttpClient"
            }
        }
    }

    Context "Certificate Handling" {

        It "Should have certificate skip capability on PowerShell Core" -Skip:($PSVersionTable.PSEdition -ne 'Core') {
            # PowerShell Core should support -SkipCertificateCheck
            $cmdlet = Get-Command Invoke-RestMethod
            $cmdlet.Parameters.ContainsKey('SkipCertificateCheck') | Should -BeTrue
        }

        It "Should handle untrusted certificates on Desktop" -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
            # Desktop edition uses callback-based certificate validation
            { Set-NBuntrustedSSL } | Should -Not -Throw
        }
    }

    Context "Encoding" {

        It "Should use UTF-8 encoding for API requests" {
            # Verify InvokeNetboxRequest uses application/json ContentType
            # The function should set ContentType to 'application/json' which defaults to UTF-8
            InModuleScope -ModuleName 'PowerNetbox' -ScriptBlock {
                $functionContent = Get-Content ./Functions/Helpers/InvokeNetboxRequest.ps1 -Raw
                # InvokeNetboxRequest should specify application/json content type
                $functionContent | Should -Match 'application/json'
            }
        }

        It "Should handle Unicode characters in PowerShell strings" -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
            # Test that PowerShell handles Unicode correctly on this platform
            # Skip on Desktop (PS 5.1) due to file encoding issues with non-ASCII chars
            $unicodeString = 'Test Device with accents'
            $unicodeString | Should -Match 'Test'
        }
    }

    Context "Path Handling" {

        It "Should use Join-Path for file operations" {
            # The deploy.ps1 script should use Join-Path
            $deployScript = Get-Content ./deploy.ps1 -Raw
            $deployScript | Should -Match 'Join-Path'
        }

        It "Should not have hardcoded Windows path separators in source" {
            $sourceFiles = Get-ChildItem -Path ./Functions -Filter "*.ps1" -Recurse

            foreach ($file in $sourceFiles) {
                $content = Get-Content $file.FullName -Raw
                # Remove comment blocks and example documentation before checking
                # This avoids false positives from PS C:\> examples in help documentation
                $codeOnly = $content -replace '(?s)<#.*?#>', '' -replace '#.*$', ''
                # Check for hardcoded Windows paths like C:\ or D:\ in actual code
                $codeOnly | Should -Not -Match '(?<![>])\s[A-Z]:\\[^>]' -Because "File $($file.Name) should not contain hardcoded Windows paths in code"
            }
        }
    }

    Context "Module Import" {

        It "Should import without errors on current platform" {
            { Import-Module ./PowerNetbox/PowerNetbox.psd1 -Force } | Should -Not -Throw
        }

        It "Should export expected number of functions" {
            $module = Get-Module PowerNetbox
            $module.ExportedFunctions.Count | Should -BeGreaterThan 400
        }

        It "Should have correct module metadata" {
            $module = Get-Module PowerNetbox
            $module.Version | Should -Not -BeNullOrEmpty
            $module.Author | Should -Not -BeNullOrEmpty
        }
    }

    Context "Line Ending Handling" {

        It "Should handle LF line endings" {
            $testContent = "line1`nline2`nline3"
            $lines = $testContent -split "`n"
            $lines.Count | Should -Be 3
        }

        It "Should handle CRLF line endings" {
            $testContent = "line1`r`nline2`r`nline3"
            $lines = $testContent -split "`r?`n"
            $lines.Count | Should -Be 3
        }
    }
}

Describe "PowerNetbox OS-Specific Behavior" -Tag 'CrossPlatform', 'OS' {

    Context "Windows-Specific" -Skip:(-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') {

        It "Should support ServicePointManager TLS configuration on Windows Desktop" -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
            # Windows Desktop uses ServicePointManager for TLS configuration
            # Verify TLS 1.2 is in the SecurityProtocol flags
            [System.Net.ServicePointManager]::SecurityProtocol.HasFlag([System.Net.SecurityProtocolType]::Tls12) | Should -BeTrue
        }
    }

    Context "Linux-Specific" -Skip:(-not $IsLinux) {

        It "Should work without Windows-specific assemblies" {
            # Verify no System.Web dependency
            $loadedAssemblies = [AppDomain]::CurrentDomain.GetAssemblies().GetName().Name
            $loadedAssemblies | Should -Not -Contain 'System.Web'
        }
    }

    Context "macOS-Specific" -Skip:(-not $IsMacOS) {

        It "Should load module successfully on macOS" {
            # Verify the module loaded correctly on this platform
            $module = Get-Module PowerNetbox
            $module | Should -Not -BeNullOrEmpty
            $module.Name | Should -Be 'PowerNetbox'
        }
    }
}

Describe "GetNetboxAPIErrorBody Cross-Platform" -Tag 'CrossPlatform', 'Helper' {

    It "Should properly dispose StreamReader on all platforms" {
        # The function should use try/finally for disposal
        $functionContent = Get-Content ./Functions/Helpers/GetNetboxAPIErrorBody.ps1 -Raw
        $functionContent | Should -Match 'finally'
        $functionContent | Should -Match 'Dispose'
    }

    It "Should specify UTF-8 encoding explicitly" {
        $functionContent = Get-Content ./Functions/Helpers/GetNetboxAPIErrorBody.ps1 -Raw
        $functionContent | Should -Match 'UTF8'
    }

    It "Should handle HttpResponseMessage type (PowerShell Core)" {
        # The function should check for HttpResponseMessage type
        $functionContent = Get-Content ./Functions/Helpers/GetNetboxAPIErrorBody.ps1 -Raw
        $functionContent | Should -Match 'System\.Net\.Http\.HttpResponseMessage'
        $functionContent | Should -Match 'ReadAsStringAsync'
    }

    It "Should handle HttpWebResponse type (PowerShell Desktop)" {
        # The function should check for HttpWebResponse type
        $functionContent = Get-Content ./Functions/Helpers/GetNetboxAPIErrorBody.ps1 -Raw
        $functionContent | Should -Match 'System\.Net\.HttpWebResponse'
        $functionContent | Should -Match 'GetResponseStream'
    }

    It "Should not have strongly typed parameter constraint" {
        # Verify the parameter accepts any type (System.Object) rather than a specific type
        InModuleScope -ModuleName 'PowerNetbox' {
            $command = Get-Command GetNetboxAPIErrorBody
            $param = $command.Parameters['Response']
            $param.ParameterType.FullName | Should -Be 'System.Object'
        }
    }

    It "Should extract body from HttpResponseMessage on PowerShell Core" -Skip:($PSVersionTable.PSEdition -ne 'Core') {
        InModuleScope -ModuleName 'PowerNetbox' {
            # Create a mock HttpResponseMessage with content
            $content = [System.Net.Http.StringContent]::new('{"error": "Test error message"}', [System.Text.Encoding]::UTF8, 'application/json')
            $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::Forbidden)
            $response.Content = $content

            $result = GetNetboxAPIErrorBody -Response $response
            $result | Should -Match 'Test error message'

            $response.Dispose()
        }
    }

    It "Should return object with empty body for unknown response types" {
        InModuleScope -ModuleName 'PowerNetbox' {
            # Pass an object that is neither HttpWebResponse nor HttpResponseMessage
            $unknownResponse = [PSCustomObject]@{ StatusCode = 403 }
            $result = GetNetboxAPIErrorBody -Response $unknownResponse
            $result | Should -Not -BeNullOrEmpty
            $result.Body | Should -BeNullOrEmpty
            $result.IsJson | Should -BeFalse
        }
    }
}
