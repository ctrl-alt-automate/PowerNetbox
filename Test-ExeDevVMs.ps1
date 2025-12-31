<#
.SYNOPSIS
    Run integration tests against exe.dev VMs via SSH tunnels.

.DESCRIPTION
    Works around PowerShell Core SSL bug by using SSH tunnels for HTTP access.
    POST/PATCH/DELETE requests fail with SkipCertificateCheck on both Linux and macOS.

.PARAMETER VM
    Which VM to test: all, plasma-paint (4.4.9), zulu-how (4.5.0), badger-victor (4.3.7)

.PARAMETER Scope
    Test scope: quick (GET only, no tunnel needed) or full (all CRUD operations)

.EXAMPLE
    ./Test-ExeDevVMs.ps1 -VM all -Scope full
    ./Test-ExeDevVMs.ps1 -VM plasma-paint -Scope quick
#>
param(
    [ValidateSet('all', 'plasma-paint', 'zulu-how', 'badger-victor')]
    [string]$VM = 'all',

    [ValidateSet('quick', 'full')]
    [string]$Scope = 'full'
)

$ErrorActionPreference = 'Stop'

# Load VM configuration
. "$PSScriptRoot/.netbox-test-vms.ps1"

# Build and import module
Write-Host "Building module..." -ForegroundColor Cyan
& "$PSScriptRoot/deploy.ps1" -Environment dev -SkipVersion | Out-Null
Import-Module "$PSScriptRoot/PowerNetbox/PowerNetbox.psd1" -Force

$vmList = if ($VM -eq 'all') { @('plasma-paint', 'zulu-how', 'badger-victor') } else { @($VM) }

# Port mapping for SSH tunnels
$tunnelPorts = @{
    'plasma-paint'  = 18001
    'zulu-how'      = 18002
    'badger-victor' = 18003
}

# Setup SSH tunnels for full scope
if ($Scope -eq 'full') {
    Write-Host "`nSetting up SSH tunnels..." -ForegroundColor Cyan

    foreach ($name in $vmList) {
        $config = $script:TestVMs[$name]
        $localPort = $tunnelPorts[$name]
        $remoteHost = $config.Hostname

        # Kill any existing tunnel on this port
        & pkill -f "ssh -L $localPort" 2>$null

        # Start new tunnel (background)
        Write-Host "  $name -> localhost:$localPort" -ForegroundColor Gray
        & ssh -L "$localPort`:localhost:8000" $remoteHost -N -f 2>$null

        Start-Sleep -Milliseconds 500
    }

    Write-Host "Tunnels ready.`n" -ForegroundColor Green
}

# Run tests for each VM
$results = @()

foreach ($name in $vmList) {
    $config = $script:TestVMs[$name]

    Write-Host "`n$('='*60)" -ForegroundColor Cyan
    Write-Host " Testing: $name (Netbox $($config.Version))" -ForegroundColor Cyan
    Write-Host "$('='*60)`n" -ForegroundColor Cyan

    if ($Scope -eq 'full') {
        # Use SSH tunnel (HTTP)
        $localPort = $tunnelPorts[$name]
        $env:NETBOX_HOST = "localhost:$localPort"
        $env:NETBOX_SCHEME = 'http'
    } else {
        # Direct HTTPS (GET only works)
        $env:NETBOX_HOST = $config.Hostname
        $env:NETBOX_SCHEME = $config.Scheme
    }

    $env:NETBOX_TOKEN = $config.Token

    # Run Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = "$PSScriptRoot/Tests/Integration.Tests.ps1"
    $pesterConfig.Filter.Tag = @('Live')
    $pesterConfig.Output.Verbosity = 'Detailed'
    $pesterConfig.Run.Exit = $false
    $pesterConfig.Run.PassThru = $true

    $result = Invoke-Pester -Configuration $pesterConfig

    $results += [PSCustomObject]@{
        VM       = $name
        Version  = $config.Version
        Passed   = $result.PassedCount
        Failed   = $result.FailedCount
        Skipped  = $result.SkippedCount
        Duration = $result.Duration
    }
}

# Cleanup SSH tunnels
if ($Scope -eq 'full') {
    Write-Host "`nCleaning up SSH tunnels..." -ForegroundColor Cyan
    foreach ($name in $vmList) {
        $localPort = $tunnelPorts[$name]
        # Kill tunnel by port (works on macOS/Linux)
        & pkill -f "ssh -L $localPort" 2>$null
    }
}

# Summary
Write-Host "`n$('='*60)" -ForegroundColor Cyan
Write-Host " Test Summary" -ForegroundColor Cyan
Write-Host "$('='*60)`n" -ForegroundColor Cyan

$results | Format-Table -AutoSize

$totalFailed = ($results | Measure-Object -Property Failed -Sum).Sum
if ($totalFailed -gt 0) {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "ALL TESTS PASSED" -ForegroundColor Green
}
