#
# Copyright 2021, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
Param()

$script:pester_site1 = "pester_site1"

# Check for required credentials
$hostname = $env:NETBOX_HOST
$token = $env:NETBOX_TOKEN

if (-not $hostname -or -not $token) {
    # Try to load from credential file
    $credentialFile = Join-Path (Join-Path $PSScriptRoot "..") "credential.ps1"
    if (Test-Path $credentialFile) {
        . $credentialFile
    }
}

# Skip if no credentials available
if (-not $hostname -or -not $token) {
    $script:SkipIntegrationTests = $true
    $script:invokeParams = @{}
    return
}

$script:SkipIntegrationTests = $false
$Credential = New-Object System.Management.Automation.PSCredential("username", (ConvertTo-SecureString $token -AsPlainText -Force))
$script:invokeParams = @{
    hostname             = $hostname
    Credential           = $Credential
    SkipCertificateCheck = $true
}