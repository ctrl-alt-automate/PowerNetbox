# NetboxPS Development Configuration
# Copy this file to .netboxps.config.ps1 and fill in your values
# .netboxps.config.ps1 is gitignored and will not be committed

@{
    # Netbox instance hostname (without https://)
    Hostname = "your-netbox-instance.example.com"

    # API Token - generate at: https://your-netbox/user/api-tokens/
    Token    = "your-api-token-here"

    # Optional: Skip SSL certificate validation (for self-signed certs)
    SkipCertificateCheck = $false

    # Optional: Custom port (default: 443)
    # Port = 443

    # Optional: Scheme (default: https)
    # Scheme = "https"
}
