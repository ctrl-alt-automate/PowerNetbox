param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "DCIM Rack Elevation Tests" -Tag 'DCIM', 'Racks', 'RackElevation' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        # Sample elevation data for mocking
        $script:MockElevationData = @(
            [PSCustomObject]@{ id = 42; device = $null }
            [PSCustomObject]@{ id = 41; device = $null }
            [PSCustomObject]@{ id = 2; device = $null }
            [PSCustomObject]@{ id = 1; device = [PSCustomObject]@{ id = 100; display = 'server-01'; name = 'server-01' } }
        )

        $script:MockRack = [PSCustomObject]@{
            id = 24
            display = 'Test-Rack-01'
            name = 'Test-Rack-01'
            u_height = 42
            site = [PSCustomObject]@{ id = 1; display = 'Test Site' }
        }
    }

    Context "Get-NBDCIMRackElevation" {
        BeforeAll {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return [ordered]@{
                    'Method' = if ($Method) { $Method } else { 'GET' }
                    'Uri'    = $URI.Uri.AbsoluteUri
                    'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
                }
            }
        }

        It "Should request rack elevation with default parameters" {
            $Result = Get-NBDCIMRackElevation -Id 24
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/24/elevation/'
        }

        It "Should request front face by default" {
            $Result = Get-NBDCIMRackElevation -Id 24
            $Result.Uri | Should -Not -Match 'face='
        }

        It "Should request rear face when specified" {
            $Result = Get-NBDCIMRackElevation -Id 24 -Face rear
            $Result.Uri | Should -Match 'face=rear'
        }

        It "Should include limit parameter" {
            $Result = Get-NBDCIMRackElevation -Id 24 -Limit 100
            $Result.Uri | Should -Match 'limit=100'
        }

        It "Should include offset parameter" {
            $Result = Get-NBDCIMRackElevation -Id 24 -Offset 50
            $Result.Uri | Should -Match 'offset=50'
        }

        It "Should combine limit and offset parameters" {
            $Result = Get-NBDCIMRackElevation -Id 24 -Limit 100 -Offset 50
            $Result.Uri | Should -Match 'limit=100'
            $Result.Uri | Should -Match 'offset=50'
        }

        It "Should accept pipeline input from Get-NBDCIMRack" {
            $mockRack = [PSCustomObject]@{ Id = 42 }
            $Result = $mockRack | Get-NBDCIMRackElevation
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/42/elevation/'
        }
    }

    Context "Get-NBDCIMRackElevation SVG Mode" {
        BeforeAll {
            # SVG mode calls Invoke-WebRequest directly (not InvokeNetboxRequest),
            # so it needs auth helper mocks for Get-NBRequestHeaders and Get-NBInvokeParams
            Mock -CommandName 'Get-NBRequestHeaders' -ModuleName 'PowerNetbox' -MockWith {
                return @{ 'Authorization' = 'Token testtoken' }
            }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith {
                return @{}
            }
            Mock -CommandName 'Invoke-WebRequest' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{
                    Content = '<svg xmlns="http://www.w3.org/2000/svg"><rect/></svg>'
                    StatusCode = 200
                }
            }
        }

        It "Should request SVG render mode" {
            $Result = Get-NBDCIMRackElevation -Id 24 -Render svg
            Should -Invoke -CommandName 'Invoke-WebRequest' -Times 1 -Exactly -Scope It -ModuleName 'PowerNetbox'
        }

        It "Should return SVG content as string" {
            $Result = Get-NBDCIMRackElevation -Id 24 -Render svg
            $Result | Should -BeOfType [string]
            $Result | Should -Match '<svg'
        }

        It "Should include render=svg in URI for SVG mode" {
            Mock -CommandName 'Invoke-WebRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($Uri)
                $Uri | Should -Match 'render=svg'
                return [PSCustomObject]@{ Content = '<svg></svg>' }
            }
            Get-NBDCIMRackElevation -Id 24 -Render svg
        }

        It "Should include include_images parameter for SVG when specified" {
            Mock -CommandName 'Invoke-WebRequest' -ModuleName 'PowerNetbox' -MockWith {
                param($Uri)
                $Uri | Should -Match 'include_images=true'
                return [PSCustomObject]@{ Content = '<svg></svg>' }
            }
            Get-NBDCIMRackElevation -Id 24 -Render svg -IncludeImages
        }
    }

    Context "Get-NBDCIMRackElevation -All Pagination" {
        BeforeAll {
            $script:CallCount = 0
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                $script:CallCount++
                if ($script:CallCount -eq 1) {
                    return @{
                        count = 84
                        next = 'https://netbox.domain.com/api/dcim/racks/24/elevation/?limit=1000&offset=1000'
                        previous = $null
                        results = @(
                            [PSCustomObject]@{ id = 42; device = $null }
                            [PSCustomObject]@{ id = 41; device = $null }
                        )
                    }
                } else {
                    return @{
                        count = 84
                        next = $null
                        previous = 'https://netbox.domain.com/api/dcim/racks/24/elevation/?limit=1000'
                        results = @(
                            [PSCustomObject]@{ id = 1; device = [PSCustomObject]@{ display = 'server-01' } }
                        )
                    }
                }
            }
        }

        It "Should paginate through all results with -All" {
            $script:CallCount = 0
            $Result = Get-NBDCIMRackElevation -Id 24 -All
            $Result.Count | Should -Be 3
            $script:CallCount | Should -Be 2
        }

        It "Should return multiple results without -Raw" {
            $script:CallCount = 0
            $Result = Get-NBDCIMRackElevation -Id 24 -All
            @($Result).Count | Should -Be 3
        }

        It "Should return structured object with -Raw" {
            $script:CallCount = 0
            $Result = Get-NBDCIMRackElevation -Id 24 -All -Raw
            $Result.count | Should -Be 3
            $Result.next | Should -BeNullOrEmpty
            $Result.results.Count | Should -Be 3
        }
    }
}

Describe "Export-NBRackElevation Tests" -Tag 'DCIM', 'Racks', 'RackElevation', 'Export' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        # Mock Get-NBDCIMRack
        Mock -CommandName 'Get-NBDCIMRack' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCustomObject]@{
                id = 24
                display = 'Test-Rack-01'
                name = 'Test-Rack-01'
                u_height = 42
                site = [PSCustomObject]@{ id = 1; display = 'Test Site' }
            }
        }

        # Mock Get-NBDCIMRackElevation
        Mock -CommandName 'Get-NBDCIMRackElevation' -ModuleName 'PowerNetbox' -MockWith {
            return @(
                [PSCustomObject]@{ id = 42; device = $null }
                [PSCustomObject]@{ id = 41; device = $null }
                [PSCustomObject]@{ id = 2; device = $null }
                [PSCustomObject]@{ id = 1; device = [PSCustomObject]@{ id = 100; display = 'server-01'; name = 'server-01'; description = 'Test server' } }
            )
        }
    }

    Context "Export-NBRackElevation Format Validation" {
        It "Should accept HTML format" {
            $Result = Export-NBRackElevation -Id 24 -Format HTML
            $Result | Should -Match '<!DOCTYPE html>'
        }

        It "Should accept Markdown format" {
            $Result = Export-NBRackElevation -Id 24 -Format Markdown
            $Result | Should -Match '## Test-Rack-01'
            $Result | Should -Match '\| U# \| Device \|'
        }

        It "Should accept Console format" {
            $Result = Export-NBRackElevation -Id 24 -Format Console
            $Result | Should -Match 'Test-Rack-01'
        }

        It "Should default to HTML format" {
            $Result = Export-NBRackElevation -Id 24
            $Result | Should -Match '<!DOCTYPE html>'
        }
    }

    Context "Export-NBRackElevation HTML Output" {
        It "Should generate valid HTML structure" {
            $Result = Export-NBRackElevation -Id 24 -Format HTML
            $Result | Should -Match '<!DOCTYPE html>'
            $Result | Should -Match '<html'
            $Result | Should -Match '</html>'
            $Result | Should -Match '<table'
        }

        It "Should include rack name in HTML" {
            $Result = Export-NBRackElevation -Id 24 -Format HTML
            $Result | Should -Match 'Test-Rack-01'
        }

        It "Should include site name in HTML" {
            $Result = Export-NBRackElevation -Id 24 -Format HTML
            $Result | Should -Match 'Test Site'
        }

        It "Should include device in HTML" {
            $Result = Export-NBRackElevation -Id 24 -Format HTML
            $Result | Should -Match 'server-01'
        }
    }

    Context "Export-NBRackElevation Markdown Output" {
        It "Should generate markdown table" {
            $Result = Export-NBRackElevation -Id 24 -Format Markdown
            $Result | Should -Match '\|---'
            $Result | Should -Match '\| U# \|'
        }

        It "Should include rack name as header" {
            $Result = Export-NBRackElevation -Id 24 -Format Markdown
            $Result | Should -Match '## Test-Rack-01'
        }

        It "Should bold device names" {
            $Result = Export-NBRackElevation -Id 24 -Format Markdown
            $Result | Should -Match '\*\*server-01\*\*'
        }

        It "Should include footer" {
            $Result = Export-NBRackElevation -Id 24 -Format Markdown
            $Result | Should -Match 'Generated by PowerNetbox'
        }
    }

    Context "Export-NBRackElevation Console Output" {
        It "Should generate ASCII box drawing" {
            $Result = Export-NBRackElevation -Id 24 -Format Console
            # Use [char] to avoid UTF-8 encoding issues on Windows PS 5.1
            $Result | Should -Match ([char]0x2554)  # ╔
            $Result | Should -Match ([char]0x2557)  # ╗
            $Result | Should -Match ([char]0x255A)  # ╚
            $Result | Should -Match ([char]0x255D)  # ╝
        }

        It "Should include rack name" {
            $Result = Export-NBRackElevation -Id 24 -Format Console
            $Result | Should -Match 'Test-Rack-01'
        }

        It "Should include ANSI color codes by default" {
            $Result = Export-NBRackElevation -Id 24 -Format Console
            # ANSI escape sequences start with ESC[
            $Result | Should -Match '\x1b\['
        }

        It "Should not include ANSI codes with -NoColor" {
            $Result = Export-NBRackElevation -Id 24 -Format Console -NoColor
            $Result | Should -Not -Match '\x1b\['
        }

        It "Should show compact output with -Compact" {
            $Result = Export-NBRackElevation -Id 24 -Format Console -Compact -NoColor
            $Result | Should -Match 'empty slots'
        }
    }

    Context "Export-NBRackElevation Face Parameter" {
        It "Should default to front face" {
            Export-NBRackElevation -Id 24 -Format Console -NoColor
            Should -Invoke -CommandName 'Get-NBDCIMRackElevation' -Times 1 -Exactly -Scope It -ModuleName 'PowerNetbox' -ParameterFilter { $Face -eq 'front' }
        }

        It "Should request rear face when specified" {
            Export-NBRackElevation -Id 24 -Format Console -NoColor -Face Rear
            Should -Invoke -CommandName 'Get-NBDCIMRackElevation' -Times 1 -Exactly -Scope It -ModuleName 'PowerNetbox' -ParameterFilter { $Face -eq 'rear' }
        }

        It "Should request both faces when specified" {
            $Result = Export-NBRackElevation -Id 24 -Format Console -NoColor -Face Both
            Should -Invoke -CommandName 'Get-NBDCIMRackElevation' -Times 2 -Exactly -Scope It -ModuleName 'PowerNetbox'
            $Result | Should -Match 'Front Face'
            $Result | Should -Match 'Rear Face'
        }
    }

    Context "Export-NBRackElevation SVG Mode" {
        BeforeAll {
            Mock -CommandName 'Get-NBDCIMRackElevation' -ModuleName 'PowerNetbox' -MockWith {
                if ($Render -eq 'svg') {
                    return '<svg xmlns="http://www.w3.org/2000/svg"><rect/></svg>'
                }
                return @([PSCustomObject]@{ id = 1; device = $null })
            }
        }

        It "Should use native renderer for SVG format" {
            $Result = Export-NBRackElevation -Id 24 -Format SVG
            $Result | Should -Match '<svg'
        }

        It "Should warn and enable UseNativeRenderer for SVG format" {
            $Result = Export-NBRackElevation -Id 24 -Format SVG -WarningVariable warnings 3>&1
            # SVG format should auto-enable UseNativeRenderer
            Should -Invoke -CommandName 'Get-NBDCIMRackElevation' -Scope It -ModuleName 'PowerNetbox' -ParameterFilter { $Render -eq 'svg' }
        }
    }

    Context "Export-NBRackElevation File Output" {
        BeforeAll {
            $tempBase = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
            $script:TestOutputDir = Join-Path $tempBase "PowerNetbox-Test-$(Get-Random)"
            New-Item -ItemType Directory -Path $script:TestOutputDir -Force | Out-Null
        }

        AfterAll {
            if (Test-Path $script:TestOutputDir) {
                Remove-Item $script:TestOutputDir -Recurse -Force
            }
        }

        It "Should write HTML file to specified path" {
            $outputPath = Join-Path $script:TestOutputDir "test.html"
            Export-NBRackElevation -Id 24 -Format HTML -Path $outputPath -Force
            Test-Path $outputPath | Should -BeTrue
            Get-Content $outputPath -Raw | Should -Match '<!DOCTYPE html>'
        }

        It "Should write Markdown file to specified path" {
            $outputPath = Join-Path $script:TestOutputDir "test.md"
            Export-NBRackElevation -Id 24 -Format Markdown -Path $outputPath -Force
            Test-Path $outputPath | Should -BeTrue
            Get-Content $outputPath -Raw | Should -Match '## Test-Rack-01'
        }

        It "Should auto-generate filename when path is directory" {
            Export-NBRackElevation -Id 24 -Format HTML -Path $script:TestOutputDir -Force
            $files = Get-ChildItem $script:TestOutputDir -Filter "*.html"
            $files.Count | Should -BeGreaterThan 0
        }

        It "Should return content with -PassThru even when writing to file" {
            $outputPath = Join-Path $script:TestOutputDir "passthru.html"
            $Result = Export-NBRackElevation -Id 24 -Format HTML -Path $outputPath -Force -PassThru
            $Result | Should -Match '<!DOCTYPE html>'
            Test-Path $outputPath | Should -BeTrue
        }
    }

    Context "Export-NBRackElevation Pipeline Support" {
        It "Should accept pipeline input from Get-NBDCIMRack" {
            $mockRack = [PSCustomObject]@{ Id = 24 }
            $Result = $mockRack | Export-NBRackElevation -Format Console -NoColor
            $Result | Should -Match 'Test-Rack-01'
        }
    }

    Context "Export-NBRackElevation Error Handling" {
        BeforeAll {
            Mock -CommandName 'Get-NBDCIMRack' -ModuleName 'PowerNetbox' -MockWith { return $null }
        }

        It "Should error when rack not found" {
            { Export-NBRackElevation -Id 99999 -Format HTML -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe "Rack Elevation Helper Functions" -Tag 'DCIM', 'Racks', 'RackElevation', 'Helpers' {
    Context "ConvertTo-NBRackConsole" {
        It "Should return array of strings" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackConsole -RackName 'Test' -UHeight 3
                $result | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Match 'String|Object'
            }
        }

        It "Should include rack name in output" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackConsole -RackName 'MyRack' -UHeight 3
                ($result -join "`n") | Should -Match 'MyRack'
            }
        }

        It "Should include site name when provided" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackConsole -RackName 'MyRack' -SiteName 'MySite' -UHeight 3
                ($result -join "`n") | Should -Match 'MySite'
            }
        }

        It "Should show face label" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackConsole -RackName 'Test' -Face 'Rear' -UHeight 3
                ($result -join "`n") | Should -Match 'Rear Face'
            }
        }

        It "Should not include ANSI codes with -NoColor" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackConsole -RackName 'Test' -UHeight 3 -NoColor
                ($result -join "`n") | Should -Not -Match '\x1b\['
            }
        }

        It "Should show device names" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $data = @([PSCustomObject]@{ id = 1; device = [PSCustomObject]@{ display = 'my-device' } })
                $result = ConvertTo-NBRackConsole -RackName 'Test' -UHeight 3 -ElevationData $data -NoColor
                ($result -join "`n") | Should -Match 'my-device'
            }
        }

        It "Should show compact summary for empty slots" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackConsole -RackName 'Test' -UHeight 10 -Compact -NoColor
                ($result -join "`n") | Should -Match 'empty slots'
            }
        }
    }

    Context "ConvertTo-NBRackHTML" {
        It "Should return valid HTML" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackHTML -RackName 'Test' -UHeight 3
                $result | Should -Match '<!DOCTYPE html>'
                $result | Should -Match '</html>'
            }
        }

        It "Should include rack name in title" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackHTML -RackName 'MyRack' -UHeight 3
                $result | Should -Match '<title>.*MyRack.*</title>'
            }
        }

        It "Should include table structure" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackHTML -RackName 'Test' -UHeight 3
                $result | Should -Match '<table'
                $result | Should -Match '</table>'
                $result | Should -Match '<tr'
            }
        }

        It "Should highlight devices" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $data = @([PSCustomObject]@{ id = 1; device = [PSCustomObject]@{ display = 'server-01'; description = 'Desc' } })
                $result = ConvertTo-NBRackHTML -RackName 'Test' -UHeight 3 -ElevationData $data
                $result | Should -Match 'server-01'
                $result | Should -Match 'class="occupied"'
            }
        }

        It "Should embed SVG when provided" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $svg = '<svg><rect/></svg>'
                $result = ConvertTo-NBRackHTML -RackName 'Test' -UHeight 3 -SvgContent $svg
                $result | Should -Match '<svg'
            }
        }
    }

    Context "ConvertTo-NBRackMarkdown" {
        It "Should return markdown table" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackMarkdown -RackName 'Test' -UHeight 3
                $result | Should -Match '\|---'
            }
        }

        It "Should include header with rack name" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackMarkdown -RackName 'MyRack' -UHeight 3
                $result | Should -Match '## MyRack'
            }
        }

        It "Should include site and height info" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackMarkdown -RackName 'Test' -SiteName 'Site1' -UHeight 42
                $result | Should -Match 'Site1'
                $result | Should -Match '42U'
            }
        }

        It "Should bold device names" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $data = @([PSCustomObject]@{ id = 1; device = [PSCustomObject]@{ display = 'server-01'; description = 'Desc' } })
                $result = ConvertTo-NBRackMarkdown -RackName 'Test' -UHeight 3 -ElevationData $data
                $result | Should -Match '\*\*server-01\*\*'
            }
        }

        It "Should include footer" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackMarkdown -RackName 'Test' -UHeight 3
                $result | Should -Match 'Generated by PowerNetbox'
            }
        }

        It "Should show face label" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NBRackMarkdown -RackName 'Test' -Face 'Rear' -UHeight 3
                $result | Should -Match 'Rear Face'
            }
        }
    }
}
