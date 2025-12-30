#Requires -Module PowerNetbox
<#
.SYNOPSIS
    Run tests against all Netbox versions on exe.dev VMs.

.DESCRIPTION
    Connects to each Netbox VM and runs the specified tests or commands.
    Useful for compatibility testing across multiple Netbox versions.

.PARAMETER TestPath
    Path to Pester test file(s) to run. Default: ./Tests/Integration.Tests.ps1

.PARAMETER Tag
    Pester tag filter. Default: 'Live'

.PARAMETER VMs
    Hashtable of VM names to Netbox versions. Uses defaults if not specified.

.PARAMETER Token
    API token for Netbox authentication. Default: test token.

.EXAMPLE
    ./Test-AllNetboxVersions.ps1

    Runs integration tests against all configured VMs.

.EXAMPLE
    ./Test-AllNetboxVersions.ps1 -Tag 'PortMapping'

    Runs only PortMapping tests against all VMs.

.EXAMPLE
    ./Test-AllNetboxVersions.ps1 -VMs @{'netbox-beta' = '4.5.0'}

    Tests only against the beta VM.
#>
[CmdletBinding()]
param(
    [string]$TestPath = "./Tests/Integration.Tests.ps1",

    [string]$Tag = "Live",

    [hashtable]$VMs = @{
        'netbox-stable'  = '4.4.9'
        'netbox-beta'    = '4.5+'      # snapshot build
        'netbox-minimum' = '4.3.7'
    },

    [string]$Token = '0123456789abcdef0123456789abcdef01234567',

    [switch]$StopOnFailure
)

$ErrorActionPreference = 'Continue'

# Results collection
$results = @()

Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           PowerNetbox Multi-Version Test Runner              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

foreach ($vm in $VMs.GetEnumerator()) {
    $vmName = $vm.Key
    $expectedVersion = $vm.Value

    Write-Host "┌─────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│ Testing: $vmName (expected: v$expectedVersion)" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow

    $result = [PSCustomObject]@{
        VM              = $vmName
        ExpectedVersion = $expectedVersion
        ActualVersion   = $null
        Connected       = $false
        TestsPassed     = 0
        TestsFailed     = 0
        TestsSkipped    = 0
        Duration        = $null
        Error           = $null
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Set environment variables for Pester
        $env:NETBOX_HOST = "$vmName.exe.dev"
        $env:NETBOX_TOKEN = $Token
        $env:NETBOX_SCHEME = 'https'

        # Connect and verify
        $secureToken = ConvertTo-SecureString $Token -AsPlainText -Force
        $cred = [PSCredential]::new('api', $secureToken)

        Write-Host "  Connecting to $vmName.exe.dev..." -ForegroundColor Gray
        Connect-NBAPI -Hostname "$vmName.exe.dev" -Credential $cred -Scheme https -SkipCertificateCheck

        $version = Get-NBVersion
        $result.ActualVersion = $version.'netbox-version'
        $result.Connected = $true

        Write-Host "  Connected! Version: $($result.ActualVersion)" -ForegroundColor Green

        # Run tests
        Write-Host "  Running tests (Tag: $Tag)..." -ForegroundColor Gray
        $pesterResult = Invoke-Pester -Path $TestPath -TagFilter $Tag -PassThru -Output Minimal

        $result.TestsPassed = $pesterResult.PassedCount
        $result.TestsFailed = $pesterResult.FailedCount
        $result.TestsSkipped = $pesterResult.SkippedCount

        if ($pesterResult.FailedCount -gt 0) {
            Write-Host "  Tests: $($pesterResult.PassedCount) passed, $($pesterResult.FailedCount) FAILED" -ForegroundColor Red

            if ($StopOnFailure) {
                throw "Tests failed on $vmName"
            }
        } else {
            Write-Host "  Tests: $($pesterResult.PassedCount) passed, $($pesterResult.SkippedCount) skipped" -ForegroundColor Green
        }
    }
    catch {
        $result.Error = $_.Exception.Message
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        $stopwatch.Stop()
        $result.Duration = $stopwatch.Elapsed
        $results += $result
    }

    Write-Host ""
}

# Summary
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                         SUMMARY                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$results | ForEach-Object {
    $status = if ($_.Error) { "❌ ERROR" }
              elseif ($_.TestsFailed -gt 0) { "⚠️  FAILED" }
              else { "✅ PASSED" }

    $versionMatch = if ($_.ActualVersion -like "$($_.ExpectedVersion)*") { "✓" } else { "?" }

    Write-Host ("  {0,-20} {1,-12} v{2,-10} {3,3}/{4,-3} tests  {5}" -f `
        $_.VM, $status, $_.ActualVersion, $_.TestsPassed, ($_.TestsPassed + $_.TestsFailed), $_.Duration.ToString('mm\:ss'))
}

Write-Host ""

# Return results for pipeline
$results
