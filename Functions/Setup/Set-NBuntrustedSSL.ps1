function Set-NBuntrustedSSL {
    <#
    .SYNOPSIS
        Disables SSL certificate validation for PowerShell Desktop (5.1).

    .DESCRIPTION
        Configures ServicePointManager to skip SSL certificate validation.
        This is only used for PowerShell Desktop (5.1) when -SkipCertificateCheck
        is specified. PowerShell Core (7+) uses the -SkipCertificateCheck parameter
        on Invoke-RestMethod directly.

    .EXAMPLE
        Set-NBuntrustedSSL

        Disables SSL certificate validation for the current PowerShell session.
        This is automatically called by Connect-NBAPI -SkipCertificateCheck on PowerShell Desktop (5.1).

    .EXAMPLE
        Set-NBuntrustedSSL -Verbose
        Connect-NBAPI -Hostname "netbox.local" -Credential $cred

        Manually disables certificate validation with verbose output, then connects to a Netbox instance
        with a self-signed certificate.

    .NOTES
        This function should only be called on PowerShell Desktop edition.
        Security Warning: Only use in development/testing environments with self-signed certificates.
        PowerShell Core (7+) uses the -SkipCertificateCheck parameter on Invoke-RestMethod directly.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType([void])]
    param()

    # Only apply to Desktop edition (PS 5.1)
    if ($PSVersionTable.PSEdition -ne 'Desktop') {
        Write-Verbose "Skipping certificate callback - not needed for PowerShell Core"
        return
    }

    # Check if callback is already set
    if ([System.Net.ServicePointManager]::ServerCertificateValidationCallback) {
        Write-Verbose "Certificate validation callback already configured"
        return
    }

    # Create callback to accept all certificates
    $CertCallback = @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public class NetboxTrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@

    # Only add type if not already loaded
    if (-not ([System.Management.Automation.PSTypeName]'NetboxTrustAllCertsPolicy').Type) {
        try {
            Add-Type -TypeDefinition $CertCallback -ErrorAction Stop
        } catch {
            Write-Verbose "Type already exists or could not be added: $_"
        }
    }

    try {
        [System.Net.ServicePointManager]::CertificatePolicy = [NetboxTrustAllCertsPolicy]::new()
        Write-Verbose "Certificate validation disabled for this session"
    } catch {
        Write-Warning "Could not set certificate policy: $_"
    }
}
