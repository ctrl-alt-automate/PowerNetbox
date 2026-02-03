function Set-NBCipherSSL {
    <#
    .SYNOPSIS
        Enables modern TLS protocols for PowerShell Desktop (5.1).

    .DESCRIPTION
        Configures ServicePointManager to use TLS 1.2 (and optionally TLS 1.3).
        This is required for PowerShell Desktop (5.1) which defaults to older protocols.
        PowerShell Core (7+) already uses modern TLS by default.

    .EXAMPLE
        Set-NBCipherSSL

        Enables TLS 1.2 (and TLS 1.3 if available) for the current PowerShell session.
        This is automatically called by Connect-NBAPI on PowerShell Desktop (5.1).

    .EXAMPLE
        Set-NBCipherSSL -Verbose

        Enables modern TLS protocols with verbose output showing which protocols were enabled.

    .NOTES
        This function should only be called on PowerShell Desktop edition.
        SSL3 and TLS 1.0/1.1 are intentionally excluded as they are deprecated.
        PowerShell Core (7+) uses modern TLS by default and does not require this function.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    # Only apply to Desktop edition (PS 5.1)
    if ($PSVersionTable.PSEdition -ne 'Desktop') {
        Write-Verbose "Skipping TLS configuration - PowerShell Core uses modern TLS by default"
        return
    }

    # Enable TLS 1.2 (required minimum for most modern APIs)
    # TLS 1.3 is available in .NET Framework 4.8+ but may not be on all systems
    try {
        # Try to enable TLS 1.2 and 1.3 if available
        $Protocols = [System.Net.SecurityProtocolType]::Tls12

        # Check if TLS 1.3 is available (requires .NET 4.8+)
        if ([Enum]::IsDefined([System.Net.SecurityProtocolType], 'Tls13')) {
            $Protocols = $Protocols -bor [System.Net.SecurityProtocolType]::Tls13
        }

        [System.Net.ServicePointManager]::SecurityProtocol = $Protocols
        Write-Verbose "Enabled TLS protocols: $([System.Net.ServicePointManager]::SecurityProtocol)"
    } catch {
        # Fallback to TLS 1.2 only
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Write-Verbose "Enabled TLS 1.2"
    }
}
