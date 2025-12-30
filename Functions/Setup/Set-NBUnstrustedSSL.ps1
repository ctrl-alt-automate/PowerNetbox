<#
.SYNOPSIS
    Configures PowerShell to trust all SSL certificates for HTTPS connections.

.DESCRIPTION
    This function disables SSL certificate validation by implementing a custom
    ICertificatePolicy that accepts all certificates. This is useful when connecting
    to Netbox instances that use self-signed certificates.

    WARNING: This reduces security by accepting any certificate. Only use in
    development environments or when connecting to trusted internal servers.

    Note: This function is only effective on Windows PowerShell (Desktop edition).
    PowerShell Core uses the -SkipCertificateCheck parameter on Invoke-RestMethod instead.

.EXAMPLE
    Set-NBUntrustedSSL

    Configures the session to trust all SSL certificates.

.EXAMPLE
    Set-NBUntrustedSSL
    Connect-NBAPI -Hostname "netbox.local" -Credential $cred

    Enables untrusted SSL before connecting to a Netbox instance with a self-signed cert.

.LINK
    Connect-NBAPI
#>
Function Set-NBUntrustedSSL {
    Write-Verbose "Processing disables"
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessforStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType([void])]
    Param()
    # Hack for allowing untrusted SSL certs with https connections
    Add-Type -TypeDefinition @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object -TypeName TrustAllCertsPolicy

}