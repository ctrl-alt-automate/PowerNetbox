<#
.SYNOPSIS
    Quick connect to development Netbox instance

.DESCRIPTION
    Loads configuration from .netboxps.config.ps1 and connects to the Netbox API.
    Use this script for local development and testing.

.EXAMPLE
    # Import module and connect
    . .\Connect-DevNetbox.ps1

.EXAMPLE
    # Just load config without connecting
    . .\Connect-DevNetbox.ps1 -ConfigOnly
#>

[CmdletBinding()]
param(
    [switch]$ConfigOnly
)

$ErrorActionPreference = 'Stop'

# Find config file
$ConfigPath = Join-Path $PSScriptRoot '.netboxps.config.ps1'

if (-not (Test-Path $ConfigPath)) {
    Write-Error @"
Configuration file not found: $ConfigPath

Please create it by copying the example:
    Copy-Item .netboxps.config.example.ps1 .netboxps.config.ps1

Then edit .netboxps.config.ps1 with your Netbox credentials.
"@
    return
}

# Load configuration
$script:NetboxDevConfig = & $ConfigPath

Write-Host "Loaded configuration for: $($script:NetboxDevConfig.Hostname)" -ForegroundColor Cyan

if ($ConfigOnly) {
    Write-Host "Config loaded. Use `$NetboxDevConfig to access settings." -ForegroundColor Yellow
    return
}

# Import module
$ModulePath = Join-Path $PSScriptRoot 'NetboxPS' 'NetboxPS.psd1'
if (-not (Test-Path $ModulePath)) {
    Write-Warning "Built module not found at $ModulePath"
    Write-Warning "Run ./deploy.ps1 first, or importing from source..."
    $ModulePath = Join-Path $PSScriptRoot 'NetboxPS.psd1'
}

Write-Host "Importing module from: $ModulePath" -ForegroundColor Cyan
Import-Module $ModulePath -Force

# Build credential
$Credential = [PSCredential]::new(
    'api',
    (ConvertTo-SecureString $script:NetboxDevConfig.Token -AsPlainText -Force)
)

# Build connection parameters
$ConnectParams = @{
    Hostname   = $script:NetboxDevConfig.Hostname
    Credential = $Credential
}

if ($script:NetboxDevConfig.SkipCertificateCheck) {
    $ConnectParams.SkipCertificateCheck = $true
}

if ($script:NetboxDevConfig.Port) {
    $ConnectParams.Port = $script:NetboxDevConfig.Port
}

if ($script:NetboxDevConfig.Scheme) {
    $ConnectParams.Scheme = $script:NetboxDevConfig.Scheme
}

# Connect
Write-Host "Connecting to Netbox API..." -ForegroundColor Cyan
Connect-NetboxAPI @ConnectParams

Write-Host ""
Write-Host "Connected to Netbox $((Get-NetboxVersion).'netbox-version')" -ForegroundColor Green
Write-Host "Ready for testing!" -ForegroundColor Green
